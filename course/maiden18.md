# maiden18 — Twin frame renderer [desk]

**Sprint goal** — Grow the twin a renderer so tracker work has
ground-truthed imagery: gradient sky, optional sun disc, and the aircraft
as a blob of physically correct pixel size.

**Depends on** — maiden12 (`maiden twin` CLI to extend), maiden16
(`azel_to_px` does the projecting).

**Read first** — lesson10.md: *How big is the target, actually*, *The
renderer is a model, and says so*, and the `twin/render.py` block in
*Build*.

## Tasks

- [ ] Implement `software/maiden/twin/render.py` per the lesson skeleton:
      `RenderConfig` (1920×1080@30, sky gradient, `noise_sigma`,
      `sun_azel`, `span_m = 1.5`) and
      `render_session(truth, station, model, pose, cfg)` yielding
      `(t_utc, image, truth_px)` frames — target drawn as a
      Gaussian-blurred ellipse of `fx·span/R` px, `truth_px` as the label.
- [ ] State the model's limits in the docstring (good enough to exercise
      the pipeline with exact truth; not evidence of field performance —
      the learned detector waits for labeled field frames).
- [ ] Wire `maiden twin --render A`: writes station A's Ch 2 H.264 video
      (IPTS per frame per IF-1) plus `labels_A.npz` of per-frame truth
      pixels; rendering stays opt-in so maiden12's fast path stays fast.
- [ ] Spot-check target pixel size at three ranges against the
      `fx·span/R` prediction (≈17 px at 150 m, 8 px at 300 m, 6 px at
      415 m for the 60° lens).

## Done when

- `maiden twin --render A` produces Ch 2 video frames plus the labels
  file on a full Sportsman session.
- The three-range pixel-size spot-check matches prediction.
- A sun-crossing render (`sun_azel` on the sequence's path) works —
  maiden19 measures its effect.

## Doc trace

SW-002 (the imagery its tracker is measured on), D5 risk R1
("twin-generated training data early" — this sprint is that row), IF-1
Ch 2, closes the frames gap lesson 07's Checkpoint deferred.
