# Loaders for the bundled normative gait reference datasets.

#' List the available normative gait datasets
#'
#' Returns the provenance / version manifest of the normative gait datasets
#' bundled with the package: dataset name, version, population, age range,
#' walking-speed condition, subject count, kinematic variables, units, data
#' source, license, and citation.
#'
#' @return A data frame, one row per dataset (class `gait_norm_catalog`).
#' @export
#' @examples
#' listGaitNorms()
listGaitNorms <- function() {
  path <- .gaitnorm_extdata("MANIFEST.csv")
  manifest <- utils::read.csv(path, stringsAsFactors = FALSE)
  class(manifest) <- c("gait_norm_catalog", "data.frame")
  manifest
}

#' Load a normative gait reference dataset
#'
#' Loads mean and standard-deviation kinematic waveform bands over the gait
#' cycle for the nine Gait Deviation Index / Gait Profile Score kinematic
#' variables, and (optionally) the normative feature reference set used to
#' construct the Gait Deviation Index.
#'
#' @param dataset Dataset name; one of [listGaitNorms()]`$dataset`
#'   (default `"adult_reference"`).
#' @param cycle Gait-cycle length in points: `101` (default) or `51`.
#' @param age Optional age in years; if given it must fall within the dataset's
#'   `age_min`/`age_max`, otherwise an error is raised (this reference set is not
#'   stratified by age).
#' @param speed Optional walking-speed condition (e.g. `"self_selected"`); if
#'   given it must match the dataset's `speed`.
#' @param features Logical; if `TRUE` (default) also load the normative feature
#'   reference matrix (subjects x concatenated 51-point kinematics) used to build
#'   the GDI basis.
#' @param reload Logical; force a re-read even if the dataset is cached.
#'
#' @return A `gait_norm` list with elements: `dataset`, `version`,
#'   `cycle_length`, `percent` (cycle sampling points), `variables`,
#'   `mean` and `sd` (each a `length(variables)` x `cycle_length` matrix, rows
#'   named by variable, columns named by cycle percentage), `units`,
#'   `features` (the feature matrix or `NULL`), and `provenance` (a one-row
#'   manifest data frame).
#'
#' @references
#' Schwartz MH, Rozumalski A (2008). "The Gait Deviation Index: a new
#' comprehensive index of gait pathology." Gait & Posture 28(3):351-357.
#' Baker R, et al. (2009). "The Gait Profile Score and Movement Analysis
#' Profile." Gait & Posture 30(3):265-269.
#'
#' @seealso [listGaitNorms()]
#' @export
#' @examples
#' norm <- loadGaitNorm("adult_reference", cycle = 101)
#' dim(norm$mean)
#' norm$variables
loadGaitNorm <- function(dataset = "adult_reference",
                         cycle = c(101, 51),
                         age = NULL, speed = NULL,
                         features = TRUE, reload = FALSE) {
  manifest <- listGaitNorms()
  if (!is.character(dataset) || length(dataset) != 1L ||
      !dataset %in% manifest$dataset) {
    stop("`dataset` must be one of: ",
         paste(manifest$dataset, collapse = ", "), ".", call. = FALSE)
  }
  info <- manifest[manifest$dataset == dataset, , drop = FALSE][1, ]

  cycle <- as.integer(cycle[1])
  if (is.na(cycle) || !cycle %in% c(51L, 101L)) {
    stop("`cycle` must be 101 or 51.", call. = FALSE)
  }
  if (!is.logical(features) || length(features) != 1L || is.na(features)) {
    stop("`features` must be TRUE or FALSE.", call. = FALSE)
  }

  if (!is.null(age)) {
    if (!is.numeric(age) || length(age) != 1L || is.na(age)) {
      stop("`age` must be a single number or NULL.", call. = FALSE)
    }
    if (age < info$age_min || age > info$age_max) {
      stop(sprintf(
        "age %.1f is outside dataset '%s' range [%g, %g]; this reference is not age-stratified.",
        age, dataset, info$age_min, info$age_max), call. = FALSE)
    }
  }
  if (!is.null(speed)) {
    if (length(speed) != 1L) {
      stop("`speed` must be a single value or NULL.", call. = FALSE)
    }
    if (!identical(as.character(speed), as.character(info$speed))) {
      stop(sprintf("speed '%s' not available for dataset '%s' (has '%s').",
                   speed, dataset, info$speed), call. = FALSE)
    }
  }

  key <- paste(dataset, cycle, features, sep = "|")
  if (!reload && exists(key, envir = .gaitnorm_cache)) {
    return(get(key, envir = .gaitnorm_cache))
  }

  variables <- strsplit(info$variables, ";", fixed = TRUE)[[1]]
  bands <- utils::read.csv(
    .gaitnorm_extdata(sprintf("%s_bands_%d.csv", dataset, cycle)),
    stringsAsFactors = FALSE)

  band_mats <- .gaitnorm_band_matrices(bands, variables, cycle)

  feat <- NULL
  if (features) {
    feat <- as.matrix(utils::read.csv(
      .gaitnorm_extdata(sprintf("%s_gdi_features.csv", dataset)),
      check.names = FALSE))
    rownames(feat) <- NULL
  }

  out <- list(
    dataset = dataset,
    version = info$version,
    cycle_length = cycle,
    percent = band_mats$percent,
    variables = variables,
    mean = band_mats$mean,
    sd = band_mats$sd,
    units = info$units,
    features = feat,
    provenance = info
  )
  class(out) <- "gait_norm"
  assign(key, out, envir = .gaitnorm_cache)
  out
}

#' Pivot the long band table into mean/sd matrices (variables x points)
#' @keywords internal
#' @noRd
.gaitnorm_band_matrices <- function(bands, variables, cycle) {
  need <- c("variable", "percent", "point", "mean", "sd")
  if (!all(need %in% names(bands))) {
    stop("normative band file is missing required columns.", call. = FALSE)
  }
  percent <- sort(unique(bands$percent))
  if (length(percent) != cycle) {
    stop(sprintf("band file has %d cycle points, expected %d.",
                 length(percent), cycle), call. = FALSE)
  }
  mk <- function(col) {
    m <- matrix(NA_real_, nrow = length(variables), ncol = cycle,
                dimnames = list(variables, as.character(percent)))
    for (v in variables) {
      sub <- bands[bands$variable == v, , drop = FALSE]
      sub <- sub[order(sub$percent), , drop = FALSE]
      if (nrow(sub) != cycle) {
        stop(sprintf("variable '%s' has %d points, expected %d.",
                     v, nrow(sub), cycle), call. = FALSE)
      }
      # The values are placed positionally into the shared percent columns, so
      # the variable must be sampled on exactly the common cycle grid (guards
      # against a regenerated/edited band file with duplicated or missing
      # percents that still totals `cycle` rows).
      if (!isTRUE(all.equal(sub$percent, percent))) {
        stop(sprintf("variable '%s' is not sampled on the common cycle grid.",
                     v), call. = FALSE)
      }
      m[v, ] <- sub[[col]]
    }
    m
  }
  list(percent = percent, mean = mk("mean"), sd = mk("sd"))
}

#' Resolve a bundled inst/extdata file, erroring clearly if the package data
#' is not installed.
#' @keywords internal
#' @noRd
.gaitnorm_extdata <- function(filename) {
  path <- system.file("extdata", filename, package = "PhysioGaitNorm")
  if (!nzchar(path)) {
    stop("Bundled data '", filename, "' not found. Is PhysioGaitNorm installed ",
         "correctly?", call. = FALSE)
  }
  path
}

#' @export
print.gait_norm <- function(x, ...) {
  cat("<gait_norm>", x$dataset, "v", x$version, "\n", sep = "")
  cat(sprintf("  cycle length : %d points\n", x$cycle_length))
  cat(sprintf("  variables    : %d (%s)\n", length(x$variables),
              paste(x$variables, collapse = ", ")))
  cat(sprintf("  bands        : mean/sd, %d x %d\n",
              nrow(x$mean), ncol(x$mean)))
  cat(sprintf("  features     : %s\n",
              if (is.null(x$features)) "not loaded" else
                paste0(nrow(x$features), " x ", ncol(x$features))))
  cat(sprintf("  population   : %s (age %g-%g, %s)\n",
              x$provenance$population, x$provenance$age_min,
              x$provenance$age_max, x$provenance$speed))
  invisible(x)
}

#' @export
print.gait_norm_catalog <- function(x, ...) {
  cat("Normative gait datasets (", nrow(x), "):\n", sep = "")
  for (i in seq_len(nrow(x))) {
    cat(sprintf("  - %s v%s: %s, age %g-%g, %d subjects, %d variables\n",
                x$dataset[i], x$version[i], x$population[i],
                x$age_min[i], x$age_max[i], x$n_subjects[i], x$n_variables[i]))
  }
  invisible(x)
}
