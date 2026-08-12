# Load a normative gait reference dataset

Loads mean and standard-deviation kinematic waveform bands over the gait
cycle for the nine Gait Deviation Index / Gait Profile Score kinematic
variables, and (optionally) the normative feature reference set used to
construct the Gait Deviation Index.

## Usage

``` r
loadGaitNorm(
  dataset = "adult_reference",
  cycle = c(101, 51),
  age = NULL,
  speed = NULL,
  features = TRUE,
  reload = FALSE
)
```

## Arguments

- dataset:

  Dataset name; one of
  [`listGaitNorms()`](https://x-biosignal.github.io/PhysioGaitNorm/reference/listGaitNorms.md)`$dataset`
  (default `"adult_reference"`).

- cycle:

  Gait-cycle length in points: `101` (default) or `51`.

- age:

  Optional age in years; if given it must fall within the dataset's
  `age_min`/`age_max`, otherwise an error is raised (this reference set
  is not stratified by age).

- speed:

  Optional walking-speed condition (e.g. `"self_selected"`); if given it
  must match the dataset's `speed`.

- features:

  Logical; if `TRUE` (default) also load the normative feature reference
  matrix (subjects x concatenated 51-point kinematics) used to build the
  GDI basis.

- reload:

  Logical; force a re-read even if the dataset is cached.

## Value

A `gait_norm` list with elements: `dataset`, `version`, `cycle_length`,
`percent` (cycle sampling points), `variables`, `mean` and `sd` (each a
`length(variables)` x `cycle_length` matrix, rows named by variable,
columns named by cycle percentage), `units`, `features` (the feature
matrix or `NULL`), and `provenance` (a one-row manifest data frame).

## References

Schwartz MH, Rozumalski A (2008). "The Gait Deviation Index: a new
comprehensive index of gait pathology." Gait & Posture 28(3):351-357.
Baker R, et al. (2009). "The Gait Profile Score and Movement Analysis
Profile." Gait & Posture 30(3):265-269.

## See also

[`listGaitNorms()`](https://x-biosignal.github.io/PhysioGaitNorm/reference/listGaitNorms.md)

## Examples

``` r
norm <- loadGaitNorm("adult_reference", cycle = 101)
dim(norm$mean)
#> [1]   9 101
norm$variables
#> [1] "pelvic_tilt"        "pelvic_obliquity"   "pelvic_rotation"   
#> [4] "hip_flexion"        "hip_adduction"      "hip_rotation"      
#> [7] "knee_flexion"       "ankle_dorsiflexion" "foot_progression"  
```
