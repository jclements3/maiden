# maiden15 — Ingest round-trip & fuzz [desk]

**Sprint goal.** Close SW-001's desk verification: the twin round-trip
proves values and time survive the full write→read cycle, and the fuzz +
truncation suite proves malformed input cannot crash ingest — VT-14's
desk half, with evidence logged.

**Depends on:** maiden13 (a trusted twin dataset), maiden14.

**Read first:** lesson08.md §Concepts (*Malformed input is a requirement,
not an edge case*), the `test_ingest.py` spec in §Build, §Verify, and
Explore 1–3.

## Tasks

- [ ] Round-trip test: run the twin at a fixed `--seed`, ingest Station A,
      join ingested az/el and v_r to `truth.npz` pre-noise values by
      timestamp; assert residual std within [0.7×, 1.3×] of the injected σ
      and residual mean ≈ 0 (the degrees/radians slip detector).
- [ ] Ordering test: `t_utc` non-decreasing per source, via
      `check_adapter_stream` from maiden08 — unchanged.
- [ ] Fuzz: corrupt the TMATS payload ≥ 500 ways (hypothesis or seeded
      byte-mangler); assert `describe()` raises `TmatsError` or returns a
      descriptor — no other exception type escapes.
- [ ] Truncation: chop a twin file at ten random offsets; `load()` yields
      only complete samples and terminates cleanly.
- [ ] Explore 1: reorder a copy so data precedes the first time packet
      beyond the queue bound; confirm the `IngestError`; write the
      fail-hard-vs-degrade decision as the `ingest.py` comment maiden26
      will hold you to.
- [ ] Explore 3: decide the SNR question — either commit the one-line D4
      IF-4 addition (plus `state.py`) per D5 change control, or write down
      why fusion shouldn't see SNR. No silent information loss.
- [ ] Log the passing pytest summary + fuzz case count + git hash to
      `results/VT-14/`.

## Done when

- `pytest software/tests/test_ingest.py -v` is green including fuzz and
  truncation; evidence in `results/VT-14/`.
- Round-trip residuals are zero-mean and match injected σ for both angles
  and v_r.
- The SNR decision exists in writing (a commit either way).

## Doc trace

SW-001 verified (desk) · VT-14 evidence logged · D4 IF-4 change control
exercised · unblocks the EKF sprints (maiden22+) with trusted data.
