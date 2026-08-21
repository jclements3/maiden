# maiden49 — .bin → Ch. 10 [desk]

**Sprint goal.** Build `maiden/convert/`: the ArduPilot DataFlash adapter
in full, the `LogAdapter` registry with the four IF-3 stubs, and the
writer that turns airborne records into a station-grade `.ch10` with a
GPS-disciplined time channel.

**Depends on.** maiden04 (Ch. 10 writer), maiden05 (TMATS generator),
maiden06 (TimeDecoder conventions). A DataFlash `.bin` with GPS lock to
develop against — maiden47's bench log if it exists yet, otherwise any
downloaded ArduPilot sample log (swap in your own before maiden50).

**Read first.** lesson22.md — *Two clocks in every log*, *Why the output
is Ch. 10 and not "just arrays"*, *The adapter registry*, and the Build
section.

**Tasks**

- [ ] `software/maiden/convert/adapters.py`: `LogAdapter` protocol,
      `AirborneRecords` dataclass (per-stream arrays: `gps`, `imu`,
      `baro`, `att`, all UTC-stamped), `get_adapter(path)` dispatching on
      suffix.
- [ ] Stubs for `.ulg`, `.bbl`, `.ubx`, EdgeTX `.csv`, each raising
      `NotImplementedError` with its D4 IF-3 row quoted in the docstring.
- [ ] `convert/ardupilot.py`: iterate messages with
      `pymavlink.DFReader_binary`; collect GPS (incl. `GWk`/`GMS`), IMU,
      BARO, ATT streams with `TimeUS`.
- [ ] Least-squares `TimeUS → UTC` fit over all GPS fixes (reject
      `GWk == 0`); apply the leap-second correction as a loudly-commented
      constant (or from the log if the firmware provides it); stamp all
      streams through the fit.
- [ ] `convert/writer.py`: `AirborneRecords` + `Airframe` descriptor →
      one `.ch10` — TMATS packet first (with
      `C\MAIDEN\AIRFRAME\...` / `C\MAIDEN\LOGGER\...` fields incl.
      `ATT_SOURCE:ARDUPILOT_EKF`), Ch 1 time packets at 1 Hz from UTC,
      PCM channels for GPS/IMU/BARO/ATT with payload structs documented
      in both the module docstring and the TMATS comment group.
- [ ] `config/airframes/<name>.yaml`: airframe name, logger serial,
      installed mass (VT-13 weigh-in when available), mount offset.
- [ ] `maiden convert LOG --airframe ... --out DIR` CLI printing per-stream
      message counts and the fit residual (RMS) of the time regression.

**Done when**

- `maiden convert` produces a `.ch10` from the development log;
  PyChapter10 opens it; TMATS parses with airframe, serial, mass, and
  mount offset present.
- The time-fit residual is printed and recorded; the first Ch 1 time
  packet's UTC equals the first GPS fix's UTC (leap correction included)
  to the millisecond.
- The registry dispatches by suffix; all four stubs raise with their
  IF-3 rows cited.

**Doc trace.** AB-002; D4 IF-3 (parser table, TMATS content); SYS-006
airborne clause. Verified fully in maiden50 (VT-09).
