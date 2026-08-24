# theremin-clash

A Clash (Haskell HDL) port of DSP blocks from
[fpga-theremin](https://github.com/fpga-theremin/theremin), kept alongside the
untouched upstream clone in `../fpga-theremin/`.

**Purpose.** This is a de-risking spike, not a rewrite. The theremin is a
known-good reference design being used to verify two things *before* radar,
cameras, and AI data fusion are layered on:

1. that Clash is a sound basis for MAIDEN's FPGA DSP work, and
2. that the MAIDEN hardware behaves.

Doing both on a design that already works means anything that breaks is
attributable to the tooling or the board, not to a half-finished datapath.

## Target part

**ULX3S 85F — Lattice ECP5 LFE5U-85F, CABGA381**, per `hardware/BOM.md`
Note A (final call at maiden36 bench bring-up). The iCEstick and HX8K are
bring-up boards only; the behavioural 512-pt FFT is ~139k LUT4s against this
part's 83,640, which is why area is the thing worth measuring.

All numbers below are from real place-and-route on that part, not estimates.

## Status

| Block | SV lines | Ported | Tests |
|---|---|---|---|
| `theremin_pwm` | 104 | yes | yes |
| `iir_nstage_pow2k` | 195 | yes | yes |
| `edge_to_pulse_position` | 78 | yes | — |
| `delay_diff_filter` | 161 | yes | — |
| `theremin_sensor_period_measure` | 515 | partial, see below | — |
| `bit_change_detector` | 269 | no | — |
| `oversampling_edge_detector` | 134 | **blocked** (ISERDESE2) | — |
| `oversampling_iserdes` | 108 | **blocked** (ISERDESE2) | — |
| `iserdes_ddr` | 123 | **blocked** (ISERDESE2) | — |
| `clock_domain_adapter` | 65 | no | — |

## Measured on ECP5 LFE5U-85F (85,640 LUT4 / 208 BRAM / 156 DSP)

Original SystemVerilog, through `yosys synth_ecp5` + `nextpnr-ecp5`:

| Module | LUT4 | FF | BRAM | Fmax |
|---|---|---|---|---|
| `iir_nstage_pow2k` | 175 | 67 | 0 | 132 MHz |
| `edge_to_pulse_position` | 25 | 37 | 0 | 328 MHz |
| `delay_diff_filter` (defaults) | 241 | 34 | 0 | 142 MHz |

`delay_diff_filter` here is at its *default* parameters (64-deep, 20-bit),
which take the distributed-RAM path. The theremin instantiates it 512-deep,
crossing `BRAM_ADDR_BITS_THRESHOLD`, so that instance trades these LUTs for a
block RAM.

**Portability result, independent of Clash:** all three of these are written
for Xilinx Series 7 and place and route on Lattice ECP5 unmodified, well above
100 MHz. `iir_nstage_pow2k`'s 8-entry state bank inferred as
`TRELLIS_DPR16X4` distributed RAM, which is what the SV comment intended on
Series 7.

## The ECP5 boundary

`theremin_sensor_period_measure` is ported *below* its front end. The SV top
instantiates `IDELAYCTRL` and two `oversampling_edge_detector`s built on
`ISERDESE2` — Xilinx primitives with no ECP5 equivalent. Getting sub-clock
edge timing on ECP5 means a redesign around `IDDRX*` / `DELAYG`.

That is a hardware design problem, not a translation problem: a hand-written
VHDL port would hit exactly the same wall. So the Clash module takes the edge
stream as inputs, matching what the detectors would present, and everything
downstream — CDC, pulse-centre averaging, both filter stages, output packing —
is ported and synthesises.

This is itself a finding for MAIDEN: **Clash does not get you out of vendor
primitives**, it only changes what surrounds them.

## Defects found in the upstream SystemVerilog

Porting forced every width to be stated explicitly, which surfaced two real
bugs. Both are reproduced faithfully in the Clash (with comments) rather than
silently fixed, so the ports stay equivalent to what the hardware does today.

1. **Volume converter parameterised with the pitch width.**
   `theremin_sensor_period_measure.sv:331` instantiates the *volume*
   `edge_to_pulse_position` with `.EDGE_POSITION_BITS(PITCH_EDGE_POSITION_BITS)`
   — 23 bits, where the volume path is 21. The 21-bit edge position is
   zero-extended in and the 24-bit result truncated back to 21 on the way out.
   Almost certainly copy-paste from the pitch instance directly above.

2. **Pulse position truncated on connection.** `edge_to_pulse_position`
   outputs `EDGE_POSITION_BITS+1` bits (it sums two edge positions, so the
   carry needs the extra bit), but the top connects it to a signal declared at
   `EDGE_POSITION_BITS`. The MSB is dropped, so a pulse-centre sum that
   overflows wraps.

## Toolchain

Nothing needs admin rights, so all of this runs on the WSL laptop.

- GHC 9.6.7 + cabal 3.14 via ghcup.
- Clash 1.8.5, pinned in `cabal.project` (the series validated against GHC
  9.6; 1.10 is untested here).
- GHDL 7.0.0-dev, Yosys 0.68, nextpnr-ecp5 from the pinned OSS CAD Suite.
  Activate per shell — do **not** put this in `.bashrc`, it shadows the system
  `python3`:

  ```sh
  source ~/tools/oss-cad-suite/environment
  ```

## Commands

```sh
make test    # Haskell behavioural tests (tasty + hedgehog)
make vhdl    # generate VHDL   -> build/vhdl/
make verilog # generate Verilog -> build/verilog/
make sim     # generate VHDL, then analyse + elaborate under GHDL
make synth   # yosys synth_ecp5
make pnr     # nextpnr-ecp5 on the LFE5U-85F
make report  # LUT/FF/BRAM/DSP usage and Fmax

# a different block:
make report TOP=Theremin.Pwm ENTITY=theremin_pwm
```

## Verification approach

1. **Model tests** — every `*Step` function is pure, so behaviour is checked
   as Hedgehog properties over full counter periods with no simulator.
   `iir_nstage_pow2k` is additionally checked against an independently written
   scalar reference chain.
2. **Generated-VHDL check** — `make sim` analyses and elaborates the Clash
   output under GHDL, catching code-generation faults a Haskell-only test
   cannot see.
3. **Place and route** — `make report` gives real area and Fmax on the target
   part, which is the number that decides whether MAIDEN fits.

## Porting notes

Details where a naive translation would have changed behaviour:

- **`RESET` is data, not a reset network.** In `theremin_pwm.sv` and
  `iir_nstage_pow2k.sv`, `RESET` is a synchronous active-high *input*. It is
  kept as an ordinary port rather than mapped to a Clash `Reset`, so the
  generated port list still matches the original.
- **Two independent `if`s, not `if/else`.** The RGB channel logic writes its
  "on" and "off" comparisons as separate non-blocking assignments to the same
  target. For a colour nibble of 0 both fire and the later (off) one wins, so
  nibble 0 means dark. Writing it as `if/else` would silently invert that.
- **The state bank survives reset.** `iir_nstage_pow2k`'s `states[8]` is RAM
  and has no reset in the SV; `filter_en` is what makes that safe. The port
  keeps the RAM contents across reset rather than zeroing them.
- **DC droop is real.** Each IIR stage stops moving once `(x - s) < 2^K`, so
  it settles up to `2^K - 1` short; five stages means a worst-case shortfall
  of 315 LSB. This is a property of the shift-based design, present in the
  hand-written SV too — not a porting artefact. The test asserts the bound
  rather than pretending the gain is exactly one.
