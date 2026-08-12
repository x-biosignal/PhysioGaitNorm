# PhysioGaitNorm

[![r-universe](https://x-biosignal.r-universe.dev/badges/PhysioGaitNorm)](https://x-biosignal.r-universe.dev/PhysioGaitNorm)
[![License:
MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://x-biosignal.github.io/PhysioGaitNorm/LICENSE)

`PhysioGaitNorm` provides versioned normative gait references for the
nine kinematic variables used by Gait Deviation Index and Gait Profile
Score workflows. Bundled manifests, provenance, and checksums make the
reference data inspectable and reproducible.

## Installation

``` r

options(repos = c(
  xbiosignal = "https://x-biosignal.r-universe.dev",
  CRAN = "https://cloud.r-project.org"
))
install.packages("PhysioGaitNorm")
```

## Quick start

``` r

library(PhysioGaitNorm)

listGaitNorms()
reference <- loadGaitNorm("adult_reference", cycle = 101)

dim(reference$mean)
reference$variables
reference$provenance
```

Use `features = FALSE` when only mean and standard-deviation waveform
bands are needed. `cycle = 51` loads the matching lower-resolution
reference.

## What it provides

| Function | Purpose |
|----|----|
| [`listGaitNorms()`](https://x-biosignal.github.io/PhysioGaitNorm/reference/listGaitNorms.md) | Inspect available datasets, population, variables, source, and license |
| [`loadGaitNorm()`](https://x-biosignal.github.io/PhysioGaitNorm/reference/loadGaitNorm.md) | Load waveform bands, optional feature matrix, and provenance |

The current adult reference covers pelvic, hip, knee, ankle, and foot
kinematics over a normalized gait cycle. It is a research reference, not
a diagnostic classification or a substitute for study-specific controls.

## Ecosystem role

The package supplies normative inputs to gait summary metrics and
rehabilitation analyses in packages such as `PhysioMoCap` and
`PhysioMSKNet`. It does not transform raw motion-capture data itself.

## Documentation

- [Function
  reference](https://x-biosignal.r-universe.dev/PhysioGaitNorm)
- [Source repository](https://github.com/x-biosignal/PhysioGaitNorm)
- [Issue tracker](https://github.com/x-biosignal/PhysioGaitNorm/issues)

## Citation

``` r

citation("PhysioGaitNorm")
```

See the ecosystem
[governance](https://github.com/x-biosignal/PhysioExperiment/blob/main/GOVERNANCE.md),
[support
policy](https://github.com/x-biosignal/PhysioExperiment/blob/main/SUPPORT.md),
and [contribution
guide](https://github.com/x-biosignal/PhysioExperiment/blob/main/CONTRIBUTING.md).

## Author and license

Author and maintainer: **Yusuke Matsui**. Licensed under the [MIT
License](https://x-biosignal.github.io/PhysioGaitNorm/LICENSE).
