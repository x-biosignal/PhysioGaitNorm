# Changelog

## PhysioGaitNorm 0.2.1

### Documentation

- A vignette carries one task end to end on synthetic or bundled data,
  offline, and is built and run by `R CMD check`.
- Runnable `@examples` added or corrected across 1 help pages. Each runs
  offline in seconds, writes nothing outside
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html), and is executed
  by `R CMD check`; anything needing a device, a download or an optional
  backend is fenced with the reason stated.

## PhysioGaitNorm 0.2.0

The bundled `adult_reference` norms are now derived from **real
motion-capture data**, replacing the previous synthetic model.

- Source: the public **WBDS** dataset (Fukuchi, Fukuchi & Duarte 2018,
  PeerJ; figshare CC-BY) — the 24 young healthy adults (age 21-37, mean
  27.6; 14 M/10 F), overground comfortable-speed walking, right limb,
  time-normalised to the gait cycle. The mean±SD bands (51- and
  101-point) and the GDI feature population are computed from these real
  per-subject waveforms (previously synthetic sin/cos curves with a
  constant SD and an `rnorm`-generated GDI population).
- Variable mapping is evidence-based: sagittal angles use the Z-axis
  convention (validated against Perry/Winter — knee-flexion amp 63.6°
  <peak@73>%, hip 39.7°, ankle 26.2°, pelvic tilt ~10.5° amp 1.9°);
  frontal/transverse axes resolved by matching published normative shape
  (pelvic obliquity, hip adduction +7° stance, etc.). foot_progression =
  FootAngleY (transverse; sign-convention noted).
- Validated: the sagittal-landmark test (VAL-11) passes against
  published ranges, and the 24 reference controls give GDI = 100.0 ±
  10.0. A patient’s GDI/GPS now reflects deviation from **real**
  normative variability rather than a fabricated constant-SD band.
- `data-raw/make_gaitnorm.R` rewritten as a real download-and-process
  script (documents the WBDS DOI, young-cohort selection and the axis
  mapping).

## PhysioGaitNorm 0.1.1

### Validation

- Added VAL-11 verification (`test-published-norms.R`): the bundled
  `adult_reference` sagittal joint-angle bands are checked to reproduce
  the published healthy-adult normative landmarks they are derived from
  (Perry & Burnfield 2010; Winter 1991; Kadaba et al. 1990) – peak knee
  flexion ~60 deg in swing, hip flexion/extension ROM ~40 deg, ankle
  dorsi/plantarflexion ROM ~28 deg, anterior pelvic tilt ~11 deg. The
  public gait databases (GaitRec, Gutenberg) contain only ground
  reaction forces, not joint kinematics, so the bands are validated
  against the published normative ranges rather than recomputed from raw
  kinematics. MANIFEST provenance updated accordingly.

## PhysioGaitNorm 0.1.0

- Initial release: bundled adult normative gait-kinematics reference
  bands and GDI feature model.
