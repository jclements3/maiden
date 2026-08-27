# Alchitry Cu arrival-day runbook — flash and listen

Prebuilt bitstreams in `bin/` (iCE40HX8K-CB132, timing-clean at 50 MHz:
selftest 58.3 MHz, jumper 62.5 MHz). Lab machine needs only git and
`openFPGALoader`, plus a micro-USB DATA cable.

## 0. Solder check
If the Br arrived without headers, solder a strip of 0.1" headers first.

## 1. Smoke test (ships-with demo)
Plug in the Cu alone. Its factory demo should light LEDs.
    openFPGALoader --detect          # should list an FTDI device
If not: try the other cable — most micro-USB cables are charge-only.

## 2. Blinky (proves OUR flow end-to-end)
    openFPGALoader -b alchitry_cu bin/blinky.bin
One LED walks along the bank about once per second.
(If `-b alchitry_cu` is not in your openFPGALoader build, fall back to
`iceprog bin/blinky.bin`.)

## 3. Theremin self-test — zero wiring
    openFPGALoader -b alchitry_cu bin/theremin-selftest.bin
Synthetic oscillators are inside: pitch sweeps on a ~1.5 s triangle.
Expect: led[3:0] flicker as a level meter (the 4-bit DAC), led[7]
shimmers (the 1-bit DSM). Audio: probe the `audio` pin (see pin caveat)
through 1 kOhm + 10 nF to a powered speaker -> a slowly sweeping tone.
This audibly validates the ENTIRE digital instrument.

## 4. Jumper test — one wire
    openFPGALoader -b alchitry_cu bin/theremin-jumper.bin
Jumper `fake_osc` to `pitch_in`: steady tone. Remove it: tone stops.
That is the real input path working.

## 5. Only now, the Colpitts breadboard (ORDERS.md section 2)
Scope each oscillator near 600 kHz BEFORE connecting; then replace the
jumper with the real oscillator output. Any new problem is analog.

## Pin caveat (the one thing to verify)
`blinky.pcf` clock/LED pins are from the Alchitry base project (high
confidence). The three Br-bank pins in `theremin.pcf` (`audio` A5,
`fake_osc` A6, `pitch_in` A7) are BEST GUESSES — verify against the
Alchitry Cu schematic/pinout before wiring; a wrong guess means
silence, never damage. To fix pins, edit `theremin.pcf`, then re-run
P&R on either machine:
    cd theremin/clash
    source ~/tools/oss-cad-suite/environment
    nextpnr-ice40 --hx8k --package cb132 --freq 50 \
      --json build/arrival/selftest.json --pcf bringup/theremin.pcf \
      --pcf-allow-unconstrained --asc /tmp/a.asc && icepack /tmp/a.asc \
      bringup/bin/theremin-selftest.bin
(The .json netlists rebuild with the commands in the Makefile if absent.)

## Note on step 3 sound
The pitch map constants are the simulation-calibrated first cut; the
sweep is designed inside their tested band (half-periods 14..29 at
50 MHz), so you should hear a sweep, but absolute pitch may be odd —
that is a constants recalibration, not a bug.
