# maiden35 — FFT + CFAR in sim [desk]

**Sprint goal.** `fft512_serial`, `cfar`, and `doppler_top` simulate green
against the golden model, and the synthesis/timing budget verdict (hx8k or
the ECP5 hatch) is recorded.

**Depends on.** maiden34.

**Read first.** lesson17.md § "The FFT, honestly budgeted", § "CA-CFAR
from first principles", § Build 3–5, § Verify 1–2.

## Tasks

- [ ] `fft512_serial.vhd` to the pinned port contract (sample_i/q +
      sample_stb at the decimated rate, `start` 50 Hz tick, streamed
      mag/mag_bin/mag_stb, done): circular input BRAM with sliding start
      pointer (the ~75%/~53% overlap is a feature — no fill-then-dump),
      ping-pong work BRAM, serialized shift-add butterfly, quarter-wave
      twiddle ROM, bit-reverse on readout.
- [ ] FFT TB: impulse → flat magnitude; single tone → energy in the right
      bin; golden-model comparison within a stated tolerance.
- [ ] Derive P_fa = (1 + α/N_t)^(−N_t) (three lines from the exponential
      CDF) and tabulate α for P_fa = 10⁻³ and 10⁻⁴ at N_t = 16; put the
      table in the cfar header comment.
- [ ] `cfar.vhd`: streaming CA-CFAR over 512 magnitudes, generics
      TRAIN/GUARD/ALPHA_Q8; outputs peak bin, peak mag, noise estimate →
      SNR; magnitude via |I|+|Q|/2-style or α-max-plus-β-min (no square
      roots on iCE40). TB drives golden spectra at known injected P_fa.
- [ ] `doppler_top.vhd`: ADC SPI master → cic_dec → fft512 → cfar → v_r
      scaling (λ generic, sign from spectrum half) → theremin `uart_tx`
      verbatim at 50 Hz (v_r, SNR, bin); no-detection ⇒ v_r held invalid
      with SNR-below-threshold report; raw I/Q pass-through for Ch 3;
      2-FF sync on all async. Frame the UART records per
      `firmware/recorder/PROTOCOL.md` — the shared tagged-record framing
      the recorder (maiden40) parses; create the file with the doppler
      record types if maiden40 hasn't yet.
- [ ] Integration TB: golden I/Q file in, UART decoded out, v_r tracks a
      commanded velocity ramp — asserts tagged `GS-002`.
- [ ] `make synth && make time` for hx8k; read the stat line (LUTs, EBR,
      fmax) and record it in the commit message. If it doesn't close,
      take the ECP5 hatch and revise D6 to say so.

## Done when

- `make sim` green for fft512_serial, cfar, and doppler_top, all
  GS-002-tagged, all driven by the committed golden model.
- The α/P_fa table and the magnitude-approximation choice are documented
  in the source headers.
- Synthesis + icetime numbers recorded; board decision (hx8k vs ECP5) is
  in the commit message and, if changed, in D6.

## Doc trace

GS-002, D6 §FPGA DSP, VT-04 (sim half — bench half is maiden36), SW-005
(TBs join the CI replay), D5 risk R2.
