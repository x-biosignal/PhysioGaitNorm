# Changelog

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
