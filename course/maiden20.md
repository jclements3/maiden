# maiden20 — Detector & 2D Kalman [desk]

**Sprint goal** — Score candidates with a classical detector and string
them through a per-station 2-D constant-velocity Kalman filter — the
lesson-12 EKF's little sibling, debugged in pixel space first.

**Depends on** — maiden19 (candidates + harness), maiden16 (camera
geometry for later emission).

**Read first** — lesson11.md: *Detection is a score, not a verdict*, *The
pixel-space Kalman filter*, and the `detector.py` / `kalman2d.py` blocks
in *Build*.

## Tasks

- [ ] Implement `software/maiden/track/detector.py`:
      `score(candidates, context) -> ndarray` weighting
      size-plausibility, normalized contrast, and motion agreement; pure
      function of its inputs so a future learned scorer is
      interchangeable (the D6 YOLO-class detector is deferred until
      labeled field frames exist — keep the boundary clean).
- [ ] Note the forward hook, don't build it: fused range from maiden24/25
      can later sharpen `size_plausibility`.
- [ ] Implement `software/maiden/track/kalman2d.py` completely and
      test it fully: `Kalman2D(dt, q, sigma_px)` with `predict()`,
      `update(z)`, `mahalanobis(z)`; state [u, v, u̇, v̇], white-accel Q,
      R = diag(σ_px²) with σ_px ≈ 1.
- [ ] Compute q from the twin's truth (worst pixel acceleration in the
      script — the snap-roll segment), not by guessing.
- [ ] Gated nearest-neighbor association on Mahalanobis distance
      (gate ≈ 9.2, 2 dof / 99 %) — adequate for D1's
      one-aircraft-in-the-box constraint.
- [ ] Build `tools/sweep_detector.py`: sweep weights/threshold, plot
      recall vs. false confirmations, pick the knee, write the curve to
      `results/VT-15/twin/`.
- [ ] Unit tests: constant-velocity synthetic target tracked with
      innovation whiteness (NIS ≈ 2-dof χ²); missed update inflates P.

## Done when

- `kalman2d` unit tests pass, including the whiteness check.
- The detector sweep is committed with the chosen operating point — tuned
  values, not magic numbers.
- On clean-sky twin imagery, scored detections follow the target through
  the full sequence when fed through the filter by hand (track
  management arrives in maiden21).

## Doc trace

SW-002, VT-15 (sweep evidence), D6 §Video tracker (two-stage design;
learned detector deferred, not forgotten), D1 (single-aircraft
constraint justifies NN association).
