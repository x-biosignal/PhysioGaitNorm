# List the available normative gait datasets

Returns the provenance / version manifest of the normative gait datasets
bundled with the package: dataset name, version, population, age range,
walking-speed condition, subject count, kinematic variables, units, data
source, license, and citation.

## Usage

``` r
listGaitNorms()
```

## Value

A data frame, one row per dataset (class `gait_norm_catalog`).

## Examples

``` r
listGaitNorms()
#> Normative gait datasets (1):
#>   - adult_reference v1.0.0: healthy_adult, age 18-45, 100 subjects, 9 variables
```
