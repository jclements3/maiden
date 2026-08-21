# maiden37 — PPS discipline & RTC [desk]

**Sprint goal.** `pps_discipline.vhd` exists and simulates green through
nominal, crystal-offset, and holdover cases with SYS-006-tagged asserts.

**Depends on.** Theremin toolchain only — pure desk VHDL; good
solder-drying filler between bench sprints.

**Read first.** lesson18.md § "The RTC and its discipline" (especially the
option-1 vs option-2 argument — MAIDEN leaves the RTC free-running and
publishes the mapping), § Build 1, § Build 4 (the TB cases this sprint
owns).

## Tasks

- [ ] Implement `firmware/timebase/pps_discipline.vhd` to the lesson's
      pinned entity: generics RTC_HZ / LOCK_TOL; 2-FF sync + rising-edge
      detect on async `pps_in`; free-running 48-bit RTC (Ch. 10 header
      width — maiden40's recorder consumes it directly); per-PPS interval
      measurement into `offset`; `locked` = last 3 intervals within
      ±LOCK_TOL; watchdog (> 1.5 s) clears `locked` for holdover.
- [ ] Note the 10 MHz derivation for hardware (12 MHz osc → PLL ×5 →
      ÷6) in the header comment; simulation drives clk directly.
- [ ] Start `timebase_tb.vhd` with a simulated GPS: PPS process with
      programmable period error and jitter via generics (deterministic —
      no `now`-based randomness, CI needs repeatability).
- [ ] TB case, nominal: PPS at exactly 1 s → `locked` within 3 s;
      SYS-006-tagged asserts.
- [ ] TB case, crystal offset +30 ppm: `offset` reports ≈ +300; still
      locked at LOCK_TOL 500.
- [ ] TB case, holdover: kill PPS 10 s → `locked` drops, RTC and outputs
      carry on; PPS returns → relock, no discontinuity assert fires.
- [ ] Makefile per the phase1 pattern; `make sim` target.

## Done when

- `make sim` in `firmware/timebase/` runs the three cases green, every
  assert tagged SYS-006.
- The 48-bit RTC and `(pps_rtc, pps_stb)` latch behave per the entity
  contract — maiden38's IRIG-B generator and maiden40's recorder build on
  them unchanged.
- You can state from memory why the RTC is free-running and where the
  RTC→UTC truth actually lives (the Ch 1 time packets + lesson 04's
  decoder).

## Doc trace

SYS-006, D6 §IRIG-B time source, D4 §Time and synchronization (station
side), D5 risk R3; feeds VT-02.
