# Generate the bundled normative gait reference data for PhysioGaitNorm.
#
# The "adult_reference" set is a REPRESENTATIVE healthy-adult normative model,
# not raw subject data: mean kinematic waveforms follow the well-established
# shapes of normal adult gait (Perry & Burnfield; Winter; Kadaba et al. 1990),
# with between-subject standard deviations of typical magnitude, and a synthetic
# normative feature population drawn around those bands so that a Gait Deviation
# Index (Schwartz & Rozumalski 2008) built from it is 100 +/- 10 by construction.
# Provenance and citations are recorded in the manifest and inst/CITATION.
#
# Run from the package root:  Rscript data-raw/make_gaitnorm.R
# Deterministic (seeded); regenerate whenever the model or points change.

set.seed(20260722L)

extdata <- file.path("inst", "extdata")
dir.create(extdata, recursive = TRUE, showWarnings = FALSE)

dataset <- "adult_reference"
version <- "1.0.0"
n_subjects <- 100L

# --- The nine GDI / GPS kinematic variables (degrees) ------------------------
variables <- c(
  "pelvic_tilt", "pelvic_obliquity", "pelvic_rotation",
  "hip_flexion", "hip_adduction", "hip_rotation",
  "knee_flexion", "ankle_dorsiflexion", "foot_progression"
)

# Between-subject SD per variable (deg), representative of normal adult gait.
sd_by_var <- c(
  pelvic_tilt = 3.0, pelvic_obliquity = 1.2, pelvic_rotation = 4.0,
  hip_flexion = 5.0, hip_adduction = 3.0, hip_rotation = 6.0,
  knee_flexion = 5.0, ankle_dorsiflexion = 4.0, foot_progression = 5.0
)

# Mean waveform of each variable as a function of gait-cycle fraction t in [0, 1]
# (0 = initial contact, ~0.6 = toe-off). Positive = flexion / anterior tilt /
# adduction / internal rotation / dorsiflexion / internal foot progression.
gauss <- function(t, mu, sigma) exp(-((t - mu) / sigma)^2)
mean_curve <- list(
  pelvic_tilt = function(t) 11 + 1.2 * cos(4 * pi * t + 0.3),
  pelvic_obliquity = function(t) 4 * sin(2 * pi * t),
  pelvic_rotation = function(t) 5 * sin(2 * pi * t - 0.4),
  hip_flexion = function(t) 10 + 20 * cos(2 * pi * t),
  hip_adduction = function(t) 3 + 5 * cos(2 * pi * t - 1.0),
  hip_rotation = function(t) -2 + 5 * sin(2 * pi * t),
  knee_flexion = function(t) 5 + 13 * gauss(t, 0.15, 0.09) +
    57 * gauss(t, 0.72, 0.11),
  ankle_dorsiflexion = function(t) 2 + 9 * gauss(t, 0.42, 0.15) -
    20 * gauss(t, 0.62, 0.07) - 4 * gauss(t, 0.08, 0.06),
  foot_progression = function(t) -7 + 2 * sin(2 * pi * t)
)
stopifnot(setequal(names(mean_curve), variables),
          setequal(names(sd_by_var), variables))

# --- Mean +/- SD bands at 101- and 51-point cycles ---------------------------
write_bands <- function(n_points) {
  t <- seq(0, 1, length.out = n_points)
  percent <- round(t * 100, 4)
  rows <- lapply(variables, function(v) {
    data.frame(
      variable = v,
      percent = percent,
      point = seq_len(n_points),
      mean = round(mean_curve[[v]](t), 5),
      sd = round(rep(sd_by_var[[v]], n_points), 5),
      stringsAsFactors = FALSE
    )
  })
  band <- do.call(rbind, rows)
  f <- file.path(extdata, sprintf("%s_bands_%d.csv", dataset, n_points))
  utils::write.csv(band, f, row.names = FALSE)
  f
}
band_files <- vapply(c(101L, 51L), write_bands, character(1))

# --- Synthetic normative feature population (51-pt) for the GDI basis ---------
# Each subject deviates from the mean by a smooth (low-frequency) perturbation
# scaled to the variable's SD; coefficients are set so the average pointwise
# variance equals sd^2. Concatenated across the 9 variables -> a 459-feature
# vector; the matrix is (n_subjects x 459).
t51 <- seq(0, 1, length.out = 51L)
pct51 <- sprintf("%03d", round(t51 * 100))
sigma_coef <- 1 / sqrt(3)   # -> average pointwise variance of the deviation = 1

feature_cols <- as.vector(t(outer(variables, pct51,
                                  function(v, p) paste0(v, "_", p))))
features <- matrix(0, nrow = n_subjects, ncol = length(feature_cols),
                   dimnames = list(NULL, feature_cols))
for (i in seq_len(n_subjects)) {
  vec <- numeric(0)
  for (v in variables) {
    co <- stats::rnorm(5, sd = sigma_coef)
    dev <- co[1] +
      co[2] * cos(2 * pi * t51) + co[3] * sin(2 * pi * t51) +
      co[4] * cos(4 * pi * t51) + co[5] * sin(4 * pi * t51)
    vec <- c(vec, mean_curve[[v]](t51) + sd_by_var[[v]] * dev)
  }
  features[i, ] <- round(vec, 5)
}
features_file <- file.path(extdata, sprintf("%s_gdi_features.csv", dataset))
utils::write.csv(as.data.frame(features), features_file, row.names = FALSE)

# --- Provenance / version manifest (with checksums) --------------------------
data_files <- c(band_files, features_file)
md5 <- tools::md5sum(data_files)

manifest <- data.frame(
  dataset = dataset,
  version = version,
  population = "healthy_adult",
  age_min = 18,
  age_max = 45,
  speed = "self_selected",
  n_subjects = n_subjects,
  n_variables = length(variables),
  cycle_lengths = "51;101",
  variables = paste(variables, collapse = ";"),
  units = "degrees",
  source = paste(
    "Representative model derived from published normal adult gait kinematics",
    "(Perry & Burnfield 2010; Winter 1991; Kadaba et al. 1990);",
    "synthetic normative feature population for GDI (Schwartz & Rozumalski 2008). Sagittal joint-angle bands verified to reproduce the published normative landmarks (tests/testthat/test-published-norms.R, VAL-11)."
  ),
  license = "CC0-1.0 (bundled reference is a derived/synthetic model)",
  citation = paste(
    "Schwartz MH, Rozumalski A (2008) Gait Posture 28:351-357;",
    "Baker R et al. (2009) Gait Posture 30:265-269."
  ),
  generated = "2026-07-22",
  stringsAsFactors = FALSE
)
# Per-file checksums recorded as separate rows for integrity tests.
checks <- data.frame(
  file = basename(names(md5)),
  md5 = unname(md5),
  stringsAsFactors = FALSE
)
utils::write.csv(manifest, file.path(extdata, "MANIFEST.csv"),
                 row.names = FALSE)
utils::write.csv(checks, file.path(extdata, "CHECKSUMS.csv"),
                 row.names = FALSE)

cat("Wrote:\n"); print(list.files(extdata))
