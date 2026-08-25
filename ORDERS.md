# MAIDEN — things to order

Shopping list for the theremin build (the de-risking vehicle for MAIDEN's
FPGA/DSP work). Spend gets recorded in `LEDGER.md` as receipts come in.

> **On the links.** I cannot browse, so I have **not** verified any specific
> product page, price, or availability — a link to a particular ASIN would be
> a guess dressed up as a fact. Every link below is an **Amazon search URL**
> for the exact part spec, which is stable and lands you on real current
> listings. Where the part is genuinely spec-critical, the requirement is
> called out in the notes so you can check the listing yourself.
>
> For the passives, Digi-Key or Mouser will be cheaper, faster to get *right*,
> and far less ambiguous than Amazon — Amazon passive kits are frequently
> mislabelled. Amazon is fine for tubing, wire, and tools.

## 1. FPGA board — ORDERED

| Item | Qty | Status |
|---|---|---|
| ULX3S 85F (Lattice ECP5 LFE5U-85F, CABGA381) | 1 | **on order** |

Not from Amazon — ULX3S ships from Radiona/Mouser/Crowd Supply. BOM #7,
Note A. The ×3 in the BOM is for the MAIDEN build; one is enough for the
theremin spike.

## 2. Oscillator circuit — ×2 (pitch and volume axes)

Values are from upstream's LTspice model,
`theremin/fpga-theremin/hardware/oscillator/2018_09_colpitts_npn_oscillator_v3.asc`
(Colpitts, NPN, 3.3 V).

| Part | Value | Qty total | Notes | Search |
|---|---|---|---|---|
| L1 | 1.45 mH | 2 | **Spec-critical.** Model assumes Rser ≈ 65 Ω. Low Q may stop the oscillator starting. | [1.45 mH inductor](https://www.amazon.com/s?k=1.45mH+inductor) · [1.5 mH RF inductor](https://www.amazon.com/s?k=1.5mH+RF+inductor) |
| C2, C3 | 220 pF | 4 | **Must be C0G/NP0.** These set the tank frequency; X7R drift = audible pitch wander. | [220pF C0G NP0 capacitor](https://www.amazon.com/s?k=220pF+C0G+NP0+capacitor) |
| C1 | 4.7 pF | 2 | **Must be C0G/NP0**, same reason. | [4.7pF C0G NP0 capacitor](https://www.amazon.com/s?k=4.7pF+C0G+NP0+capacitor) |
| C4 | 1 µF | 2 | Decoupling; dielectric not critical. | [1uF ceramic capacitor kit](https://www.amazon.com/s?k=1uF+ceramic+capacitor) |
| R1 | 470 kΩ | 2 | 1/4 W, 1% | [470k ohm resistor 1%](https://www.amazon.com/s?k=470k+ohm+resistor+1%25) |
| R2 | 2.7 kΩ | 2 | 1/4 W, 1% | [2.7k ohm resistor 1%](https://www.amazon.com/s?k=2.7k+ohm+resistor+1%25) |
| Rant | 10 MΩ | 2 | Antenna bleed resistor | [10M ohm resistor](https://www.amazon.com/s?k=10M+ohm+resistor) |
| U1 | BC547C | 2 | Buy extras, they're pennies | [BC547C transistor](https://www.amazon.com/s?k=BC547C+transistor) |
| U2 | 74HC04 | 2 | Hex inverter, **3.3 V operation** | [74HC04 hex inverter](https://www.amazon.com/s?k=74HC04+hex+inverter) |

**PCBs:** upstream ships fabricable gerbers at
`hardware/oscillator/npn_oscillator_2018_v6_gerber.zip`. Send to JLCPCB /
PCBWay (~$5 for five) rather than Amazon. Or breadboard the first one — but
note breadboard stray capacitance will shift the tank frequency, so expect to
re-tune when you move to a board.

## 3. Antennas

The schematic models the antenna only as `Cant = 7 pF`, so physical dimensions
are a free choice. These are conventional theremin proportions:

| Item | Spec | Qty | Search |
|---|---|---|---|
| Pitch antenna | ~1/2" (12 mm) OD tube, ~18" long, aluminium or brass | 1 | [1/2 inch aluminum tube](https://www.amazon.com/s?k=1%2F2+inch+aluminum+tubing+round) · [brass tubing 1/2 inch](https://www.amazon.com/s?k=brass+tubing+1%2F2+inch) |
| Volume antenna | Same tubing, formed into a ~10" diameter loop | 1 | (same stock as above — buy enough length for both) |
| Shielded coax | Short runs, antenna to oscillator | 1 | [RG178 coax cable](https://www.amazon.com/s?k=RG178+coaxial+cable) · [RG316 coax](https://www.amazon.com/s?k=RG316+coaxial+cable) |

**This matters more than the part numbers:** the antenna-to-oscillator lead is
*part of the tank capacitance*. Keep each run short, mechanically rigid, and
identical between builds — a lead that flexes is a pitch that drifts. Ground
the coax shield at the oscillator end only.

## 4. Test equipment

| Item | Why | Search |
|---|---|---|
| Oscilloscope or frequency counter | **Most likely bring-up blocker.** You must confirm each oscillator starts and runs near design frequency, and that the two aren't pulling each other. Invisible from the FPGA side. | [digital oscilloscope 100MHz](https://www.amazon.com/s?k=digital+oscilloscope+100MHz) · [frequency counter 10MHz](https://www.amazon.com/s?k=frequency+counter+module) |
| Breadboard + jumpers | First oscillator bring-up | [breadboard jumper wire kit](https://www.amazon.com/s?k=breadboard+jumper+wire+kit) |
| Dupont / header wire | Board to oscillator | [dupont wire kit](https://www.amazon.com/s?k=dupont+jumper+wire+kit) |

If you already have a scope on the bench, skip this section entirely.

## 5. Audio output

The ULX3S has a 3.5 mm jack driven by an on-board resistor DAC. That is very
likely good enough to hear the thing work, so **buy nothing here until the
sensor path runs**. Only if the resistor DAC proves too noisy would you add an
I²S DAC board ([I2S DAC module](https://www.amazon.com/s?k=I2S+DAC+module+PCM5102)).

## 6. Not needed

- **iCE40 boards** — you already own the iCEstick and HX8K breakout (BOM #8,
  marked OWNED). They are bring-up boards and too small for the FFT anyway.
- **Xilinx/Zynq board** — would let you run upstream's ISERDES front end
  unmodified, but proves the toolchain on hardware MAIDEN will never use.
  Deliberately rejected.
- **Anything for the ISERDES gap** — resolved in software. See
  `theremin/clash/src/Theremin/EdgeSampler.hs`: plain 1x sampling plus the
  existing 512-tap averaging gives ~0.02 cent resolution, so no exotic
  front-end hardware is required.

## Cameras (MAIDEN proper, not the theremin)

BOM #4, Note B — global shutter, hardware strobe out, USB3, C/CS mount, three
lens fields (60°/35°/60° per D6). Model not yet selected; the rolling-shutter
warning in lesson 16 is the reason for the global-shutter requirement. Not an
Amazon purchase — machine-vision vendors (FLIR, Basler, IDS).
