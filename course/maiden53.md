# maiden53 — Rubric Scoring [desk]

**Sprint goal.** Grade recognized maneuvers with deterministic,
inspectable geometry checks: 0–10 per maneuver with itemized
plain-language deductions, per the actual AMA rubric.

**Depends on.** maiden51 (maneuver Events), maiden02
(`config/field/rcrc.yaml` box/centerline geometry).

**Read first.** lesson23.md — *Scoring is geometry first, judgment
second*, and the `maiden/score.py` items in the Build section.

**Tasks**

- [ ] Download the current AMA Radio Control Aerobatics rulebook
      (modelaircraft.org → Competition → Rulebooks; the Sportsman
      schedule); put the relevant sections in `docs/refs/`. The rubric is
      fetched, not invented.
- [ ] `software/maiden/score.py`: `Deduction(text, points, tag)` and
      `ManeuverScore(cls, raw, calibrated, deductions)`.
- [ ] Per-class check functions citing AMA paragraph numbers in their
      docstrings: loop/Immelmann roundness via circle fit (algebraic
      fit, then geometric refinement) in the maneuver's vertical plane —
      radius variance as the deduction; line fits for legs and
      up/down-lines; centering as offset from the pattern-box
      centerline; track as heading deviation from the box axis;
      entry/exit altitude match.
- [ ] Every deduction emits a magnitude and a sentence ("loop 4 m
      narrower at the top than the bottom"); maneuver score = 10 −
      summed deductions, floored at 0.
- [ ] `score_sequence(events, samples) -> list[ManeuverScore]` — the
      entry point the report calls.
- [ ] The null test: a *clean* twin session must score near 10 with
      near-empty deduction lists — this catches sign errors in every
      geometry check at once. Then an `--imperfect` session must print
      one 0–10 line per maneuver with itemized deductions (the VT-20
      shape).
- [ ] Determinism test: same session, same scores, bit-for-bit.

**Done when**

- `score_sequence` runs on twin sessions: clean ≈ 10s, imperfect shows
  proportionate itemized deductions in plain language.
- Every check function cites its AMA paragraph; the rulebook extract is
  in `docs/refs/`.
- Scores are deterministic across runs (CI will rely on this).

**Doc trace.** SYS-007; VT-20 (demonstrable on twin data); D6 §Scoring
rubric layer; D5 risk R6 (the deterministic layer is the mitigation's
first half — maiden54 is the second).
