library(testthat)
library(PhysioGaitNorm)

# VAL-11: verify the bundled adult_reference normative bands reproduce published
# healthy-adult gait-kinematics landmarks (Perry & Burnfield 2010; Winter 1991;
# Kadaba et al. 1990). The public GRF gait databases (GaitRec, Gutenberg) contain
# no joint kinematics, so the sagittal normative bands are validated against the
# published normative RANGES they are derived from, turning the MANIFEST's
# "derived" claim into a tested one (regression + published-value check).

.bands <- function() {
  f <- system.file("extdata", "adult_reference_bands_101.csv",
                   package = "PhysioGaitNorm")
  skip_if(f == "", "adult_reference bands not bundled")
  read.csv(f)
}
.range <- function(b, v) { x <- b[b$variable == v, "mean"]; c(min = min(x), max = max(x)) }
.peak_pct <- function(b, v) { x <- b[b$variable == v, ]; x$percent[which.max(x$mean)] }

test_that("sagittal joint-angle landmarks match published adult norms", {
  b <- .bands()

  # Knee flexion: swing peak ~60 deg (Perry ~60, Kadaba 60-70), ROM ~55-65 deg
  kf <- .range(b, "knee_flexion")
  expect_gte(kf["max"], 55); expect_lte(kf["max"], 70)          # swing-peak flexion
  expect_lte(kf["min"], 10)                                     # near-extension at stance
  expect_gte(kf["max"] - kf["min"], 50)                         # sagittal knee ROM
  expect_gte(.peak_pct(b, "knee_flexion"), 65)                  # peak in swing (~70-75%)
  expect_lte(.peak_pct(b, "knee_flexion"), 80)

  # Hip flexion: ~25-40 deg peak (IC/early swing), ~-5..-15 deg extension; ROM ~35-50
  hf <- .range(b, "hip_flexion")
  expect_gte(hf["max"], 25); expect_lte(hf["max"], 40)
  expect_lte(hf["min"], -5); expect_gte(hf["min"], -20)
  expect_gte(hf["max"] - hf["min"], 35); expect_lte(hf["max"] - hf["min"], 50)

  # Ankle dorsiflexion: DF peak ~5-15 deg (stance), PF push-off ~-10..-25; ROM ~20-35
  af <- .range(b, "ankle_dorsiflexion")
  expect_gte(af["max"], 5);  expect_lte(af["max"], 15)
  expect_lte(af["min"], -10); expect_gte(af["min"], -25)
  expect_gte(af["max"] - af["min"], 20); expect_lte(af["max"] - af["min"], 35)
})

test_that("pelvic tilt is anterior and near-constant per published norms", {
  b <- .bands()
  pt <- .range(b, "pelvic_tilt")
  expect_gte(pt["min"], 5); expect_lte(pt["max"], 16)           # anterior tilt ~8-15 deg
  expect_lte(pt["max"] - pt["min"], 6)                          # small excursion over the cycle
})
