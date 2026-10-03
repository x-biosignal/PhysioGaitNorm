# Package-level cache for loaded normative datasets.
.gaitnorm_cache <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  rm(list = ls(envir = .gaitnorm_cache), envir = .gaitnorm_cache)
}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "PhysioGaitNorm v", utils::packageVersion(pkgname),
    " - normative gait reference database"
  )
}
