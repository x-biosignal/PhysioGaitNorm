library(testthat)
library(PhysioGaitNorm)

# --- catalogue ----------------------------------------------------------------

test_that("listGaitNorms returns a provenance manifest", {
  cat <- listGaitNorms()
  expect_s3_class(cat, "gait_norm_catalog")
  expect_true(all(c("dataset", "version", "population", "age_min", "age_max",
                    "speed", "n_subjects", "n_variables", "variables", "units",
                    "source", "license", "citation") %in% names(cat)))
  expect_true("adult_reference" %in% cat$dataset)
})

# --- loader shape / integrity -------------------------------------------------

test_that("loadGaitNorm returns mean+SD bands with the expected variables", {
  expected_vars <- c(
    "pelvic_tilt", "pelvic_obliquity", "pelvic_rotation",
    "hip_flexion", "hip_adduction", "hip_rotation",
    "knee_flexion", "ankle_dorsiflexion", "foot_progression"
  )
  for (cyc in c(101L, 51L)) {
    norm <- loadGaitNorm("adult_reference", cycle = cyc)
    expect_s3_class(norm, "gait_norm")
    expect_identical(norm$cycle_length, cyc)
    expect_identical(norm$variables, expected_vars)
    expect_equal(dim(norm$mean), c(9L, cyc))
    expect_equal(dim(norm$sd), c(9L, cyc))
    expect_identical(rownames(norm$mean), expected_vars)
    expect_identical(colnames(norm$mean), colnames(norm$sd))
    expect_length(norm$percent, cyc)
    expect_equal(range(norm$percent), c(0, 100))
    expect_true(all(is.finite(norm$mean)))
    expect_true(all(norm$sd > 0))
  }
})

test_that("the GDI feature matrix is subjects x (9 variables x 51 points)", {
  norm <- loadGaitNorm("adult_reference", cycle = 51, features = TRUE)
  expect_false(is.null(norm$features))
  expect_equal(ncol(norm$features), 9L * 51L)
  expect_equal(nrow(norm$features), norm$provenance$n_subjects)
  expect_true(all(is.finite(norm$features)))
})

test_that("features = FALSE skips the feature matrix", {
  norm <- loadGaitNorm("adult_reference", features = FALSE)
  expect_null(norm$features)
})

# --- checksum / dimension integrity -------------------------------------------

test_that("bundled data files match their recorded MD5 checksums", {
  dir <- system.file("extdata", package = "PhysioGaitNorm")
  checks <- utils::read.csv(file.path(dir, "CHECKSUMS.csv"),
                            stringsAsFactors = FALSE)
  for (i in seq_len(nrow(checks))) {
    f <- file.path(dir, checks$file[i])
    expect_true(file.exists(f), info = checks$file[i])
    expect_identical(unname(tools::md5sum(f)), checks$md5[i],
                     info = checks$file[i])
  }
})

test_that("the manifest is internally consistent with the loaded data", {
  cat <- listGaitNorms()
  info <- cat[cat$dataset == "adult_reference", ]
  norm <- loadGaitNorm("adult_reference", cycle = 51)
  expect_equal(length(norm$variables), info$n_variables)
  expect_equal(nrow(norm$features), info$n_subjects)
  vars_manifest <- strsplit(info$variables, ";", fixed = TRUE)[[1]]
  expect_identical(norm$variables, vars_manifest)
})

# --- GDI-by-construction invariant (what WS4-09 relies on) --------------------

test_that("a Schwartz-Rozumalski GDI on the control set is 100 +/- 10", {
  norm <- loadGaitNorm("adult_reference", cycle = 51)
  G <- norm$features
  gbar <- colMeans(G)
  Gc <- sweep(G, 2, gbar)
  V <- svd(Gc)$v[, 1:15, drop = FALSE]
  D <- sqrt(rowSums((Gc %*% V)^2))
  expect_true(all(D > 0))
  z <- (log(D) - mean(log(D))) / stats::sd(log(D))
  gdi <- 100 - 10 * z
  expect_equal(mean(gdi), 100, tolerance = 1e-6)
  expect_equal(stats::sd(gdi), 10, tolerance = 1e-6)
})

# --- argument validation ------------------------------------------------------

test_that("loadGaitNorm validates dataset, cycle, age and speed", {
  expect_error(loadGaitNorm("nope"), "must be one of")
  expect_error(loadGaitNorm(cycle = 99), "must be 101 or 51")
  expect_error(loadGaitNorm(age = 90), "outside dataset")
  expect_error(loadGaitNorm(age = 5), "outside dataset")
  expect_error(loadGaitNorm(speed = "sprint"), "not available")
  # in-range age / matching speed are accepted
  expect_s3_class(loadGaitNorm(age = 30, speed = "self_selected"), "gait_norm")
})

test_that("results are cached and reload refreshes", {
  a <- loadGaitNorm("adult_reference", cycle = 101)
  b <- loadGaitNorm("adult_reference", cycle = 101)
  expect_identical(a, b)
  d <- loadGaitNorm("adult_reference", cycle = 101, reload = TRUE)
  expect_equal(d$mean, a$mean)
})

# --- regression tests for adversarial-review findings (WS4-08) ----------------

test_that(".gaitnorm_band_matrices rejects a variable off the common cycle grid", {
  # two variables, 3-pt cycle; 'a' has a duplicated percent and is missing 100,
  # 'b' supplies 100 so the GLOBAL axis is {0,50,100} (length 3 == cycle).
  bands <- data.frame(
    variable = c("a", "a", "a", "b", "b", "b"),
    percent  = c(0, 50, 50, 0, 50, 100),
    point    = c(1, 2, 3, 1, 2, 3),
    mean     = c(10, 20, 30, 40, 50, 60),
    sd       = rep(1, 6),
    stringsAsFactors = FALSE
  )
  expect_error(
    PhysioGaitNorm:::.gaitnorm_band_matrices(bands, c("a", "b"), cycle = 3),
    "common cycle grid"
  )
})

test_that("loadGaitNorm validates the length of the speed argument", {
  expect_error(
    loadGaitNorm(speed = c("self_selected", "self_selected")),
    "single value"
  )
  # a matching length-1 speed is still accepted
  expect_s3_class(loadGaitNorm(speed = "self_selected"), "gait_norm")
})
