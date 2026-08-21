# maiden24 — Radial-velocity updates [desk]

**Sprint goal.** Give the filter direct velocity observability: the v_r
measurement model with its full Jacobian (position term included),
chi-square innovation gating on both update paths, and a numerical proof
of D3's three-radials argument.

**Depends on.** maiden22–23 (Ekf core + A+B driver), maiden11 (twin v_r
sensor model and its sign convention).

**Read first.** lesson13.md — *Concepts* "The v_r measurement model",
"The Jacobian, including the term everyone forgets", "Why three radials
give you the whole vector", and "Gating: refusing to believe nonsense".

## Tasks

- [ ] Derive H_vr on paper: ∂h/∂v = ûᵀ and
      ∂h/∂p = vᵀ(I₃ − ûûᵀ)/‖d‖ via the unit-vector identity — then
      implement `Ekf.update_vr(vr, pose, sigma_vr)`.
- [ ] Write down the v_r sign convention in `fuse.py` (positive =
      receding, h = d(range)/dt) and confirm it matches the twin's.
- [ ] `test_jacobian_vr`: analytic H_vr vs central finite differences,
      random states/poses, 1e-6 relative — the position block is the part
      this test exists to catch.
- [ ] `software/tests/test_three_radials.py`: one twin epoch, build U
      from the three true unit vectors, solve U⁻¹vr, compare to twin
      truth velocity to injected-noise levels. Keep it as documentation
      of the mechanism.
- [ ] Implement `Ekf.gate(y, S, m)`: reject when γ = yᵀS⁻¹y exceeds the
      χ²(m) 0.999 quantile — 13.82 for m = 2 (az/el), 10.83 for m = 1
      (v_r). Rejected measurements are logged, never applied; count them.
- [ ] `test_gating`: inject a 30σ az outlier into a twin stream; the gate
      rejects it and final RMS matches the clean run.
- [ ] Use σ_vr from the twin's injected Doppler noise for R; leave a note
      that the bench value arrives with the lesson 17 hardware.

## Done when

- Both new tests pass alongside the maiden22 suite; the finite-difference
  check covers the position block of H_vr.
- The three-radials demo recovers full 3D velocity from a single epoch —
  no differencing of positions — and you can restate why conditioning
  degrades when all û_i point the same way.
- Gate-rejection counters exist and the outlier test shows the gate
  protecting the track.

## Doc trace

SYS-003 (sim rehearsal; VT-11 binds in the field); D3 §Fusion concept
(three radial velocities → 3D velocity); D6 §Fusion EKF
(missing-measurement robustness begins here, completed in maiden25).
