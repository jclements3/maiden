# maiden56 — Approach Metrics [desk]

**Sprint goal.** Measure the landing: glideslope with a fit standard
error, threshold speed cross-checked against Station C's radar, touchdown
point and session scatter — rehearsed against twin truth.

**Depends on.** maiden25 (FUSED tracks), maiden51 (maneuver Events for
final-leg segmentation), maiden10 (twin scripted landings), maiden55
(report panel slot to fill).

**Read first.** lesson24.md — *The approach, as an estimation problem*,
and the `maiden/approach.py` item in the Build section.

**Tasks**

- [ ] `software/maiden/approach.py`:
      `approach_metrics(samples, events, field) -> ApproachReport`, where
      `field` is the parsed `rcrc.yaml` (runway heading, threshold and
      target marks).
- [ ] Final-leg segmentation: last level/descending leg before touchdown
      from Events, or direct detection (heading within tolerance of
      runway heading, altitude monotonically decreasing,
      distance-to-threshold decreasing).
- [ ] Glideslope: fit U against along-track distance-to-threshold;
      report angle **with its fit standard error** — never a bare
      number (D9's "bands matter" rule applies here first).
- [ ] Threshold speed: |v| from FUSED at threshold crossing,
      cross-checked against Station C's v_r corrected by the cosine of
      the flight-path/boresight angle.
- [ ] Touchdown: vertical-speed zero at ground height; the Station C
      video refinement is a **marked stub** (twin has no flare imagery).
      Session touchdown scatter plotted against the target mark.
- [ ] Hook the `ApproachReport` into maiden55's approach panel.
- [ ] `software/tests/test_approach.py` on a twin session with scripted
      landings: glideslope within tolerance of the twin's scripted
      value; threshold speed within 1 m/s of twin truth (the VT-22
      number, rehearsed). Record results in `results/VT-22/rehearsal/`.

**Done when**

- `pytest software/tests/test_approach.py` passes; rehearsal numbers
  committed under `results/VT-22/rehearsal/`.
- The report's approach panel renders glideslope ± se, threshold speed
  (fused + C cross-check), touchdown, and scatter from a twin session.
- The fused-vs-C-radar cross-check disagreement is computed and shown —
  it's a live health indicator at the field, not just a test artifact.

**Doc trace.** SYS-009; VT-22 (binding test is against truth in the
campaign — today is rehearsal); D6 §Field-rule checker and approach
metrics; D9 approach panel.
