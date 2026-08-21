# maiden13 — Triangulation sanity [desk]

**Sprint goal.** Verify D3's error formula σ_range ≈ R²·σ_θ/B empirically
against a Monte-Carlo triangulation of your own twin output — the first
quantitative evidence that SYS-002's 1.0 m budget has margin.

**Depends on:** maiden11 (noisy az/el streams), maiden12 (default layout
and seeds; the baseline-sweep artifact lands in `results/`).

**Read first:** lesson07.md §Verify (*The D3 formula, empirically*) and
D3 §Fusion concept (Figure 2 and the σ_range line under it).

## Tasks

- [ ] Write the Monte-Carlo test (test or notebook, but the assert lives
      in pytest): generate noisy az/el from A and B, no dropouts;
      least-squares ray-intersection per frame pair; collect the position
      scatter over the sequence.
- [ ] Compare the range-direction scatter against σ_range ≈ R²·σ_θ/B at
      the default geometry (R = 150 m, σ_θ = 0.5 mrad, B = 75 m →
      ≈ 0.15 m); assert agreement within a factor of ~1.5.
- [ ] Assert cross-range scatter is markedly smaller than range scatter,
      and comment *why* the scalar formula is not exact (small-angle
      sketch of a 3D problem).
- [ ] Explore 1 (required here, not optional): regenerate with B at 25 m,
      confirm ≈ 0.45 m, plot σ_range vs B, and commit the figure under
      `results/` — this is the standing answer to "why must B be 75 m
      down the fence?"
- [ ] Optional but cheap: lesson07 Explore 3 — bias Station B's time by
      33 ms, re-triangulate, compare against lesson 04's one-frame ≈ 1 m
      argument. Keep the switch; maiden26's validate tool must catch this
      fault class.

## Done when

- The Monte-Carlo pytest passes at the default geometry and the 1/B
  scaling holds at B = 25 m.
- The σ_range-vs-B figure is committed under `results/` with the
  generating seed and git hash noted.
- A comment in the test explains the factor-of-~1.5 tolerance honestly.

## Doc trace

D3 §Fusion concept (made executable) · SYS-002 error budget evidence ·
GS-004/GS-005 rationale (why survey and baseline dominate) · feeds the
maiden22–25 EKF work with a known-good geometry baseline.
