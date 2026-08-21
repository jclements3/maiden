# maiden54 — Calibration Layer (Untrained) [desk]

**Sprint goal.** Build the rubric→judge calibration layer — trainable,
saveable, loadable, contract-documented — and leave it honestly untrained
until maiden64 delivers real judge sheets.

**Depends on.** maiden53 (rubric scores). Trains for real in maiden64.

**Read first.** lesson23.md — the calibration paragraphs in *Scoring is
geometry first, judgment second*, and the `Calibration` item in the
Build section.

**Tasks**

- [ ] `Calibration` class in `score.py`: per-maneuver-class isotonic
      regression (sklearn `IsotonicRegression`) from rubric deduction
      totals to judge scores; `fit(judge_sheets)`, `save`, `load`.
- [ ] Document the judge-sheet CSV schema in the docstring — keyed by
      flight and maneuver; this is the data contract the campaign
      (maiden64) must produce, so write it as a contract, not a wish.
- [ ] Wire the untrained path: `ManeuverScore.calibrated` is `None`
      until a fit exists, and the report must label raw rubric scores as
      such (maiden55 consumes this flag).
- [ ] Smoke-test fit/save/load on a *synthetic* sheet (labeled synthetic
      — this proves the plumbing, not SYS-008; say so in the test name).
- [ ] Explore: lesson 23's "judge yourself" drill — score one twin
      session by eye from Station A's synthetic geometry, compare your
      sheet to the rubric's. Your self-disagreement previews D5 risk R6
      and what r ≥ 0.8 actually demands; keep the sheet in
      `results/VT-21/rehearsal/`.

**Done when**

- `Calibration` round-trips fit/save/load on the synthetic sheet;
  monotonicity holds by construction.
- The judge-sheet CSV schema is documented and referenced from
  lesson 99's campaign procedure (check the pointer resolves).
- The `calibrated=None` path flows through `score_sequence` without
  special-casing downstream.

**Doc trace.** SYS-008 / VT-21 (cannot bind before the campaign — the
code ships now, the fit happens in maiden64); D5 risk R6; D8 judge
correlation table is where the result lands.
