# Hardware BOM — lessons 16–21 (sprints 31–48)

Source: lesson 16 §The shopping list, plus the MCP3202-class ADC line the
lesson 17 chain needs (called out by maiden30 — it is not a separate
table line in lesson 16). Owned items per the theremin course inventory.

Update the Status column on order and again on arrival. Placing orders
and recording order numbers/ETAs is a human task (see card note).

| # | Item | Qty | For (req) | ~Cost | Status | Order # / ETA |
|---|------|-----|-----------|-------|--------|----------------|
| 1 | CDM324 24 GHz Doppler module | 3 + 1 spare | GS-003 radar, all stations (D5 R2: A/B stock) | $40 | TO ORDER | — |
| 2 | HB100 10.5 GHz Doppler module | 2 | GS-003 fallback per VT-05 | $0 | **OWNED** (theremin) | — |
| 3 | NE5532 / MCP6022 op-amps, passives kit, trimmers | kit | LNA + AAF ×3 (GS-002 chain) | $25 | TO ORDER | — |
| 4 | 1080p30 global-shutter USB3 machine-vision camera + lens | 3 (60°, 35°, 60°) | GS-001 — confirm global shutter AND strobe output in the datasheet before ordering; do not cheap out | $450 | TO ORDER (model TBD at order time) | — |
| 5 | u-blox MAX-M10S breakout with PPS pin | 4 (3 stations + logger) | SYS-006, AB-001 | $80 | TO ORDER | — |
| 6 | Raspberry Pi 5 (8 GB) + SSD + SD card | 3 | SYS-005 Ch. 10 recorders | $360 | TO ORDER | — |
| 7 | FPGA dev board (see note A) | 3 | GS-002 DSP + SYS-006 timebase | $180–540 | TO ORDER after note A decision | — |
| 8 | iCEstick + HX8K breakout | 1 + 1 | dev/bring-up boards | $0 | **OWNED** (theremin) | — |
| 9 | MCP3202-class SPI ADC (2 ch, 12-bit) | 3 + 1 spare | lesson 17 I/Q capture front end | $45 | 1 **OWNED** (theremin), 3 TO ORDER | — |
| 10 | Matek H743 + M10 GNSS | 1 | AB-001 truth logger | $110 | TO ORDER | — |
| 11 | 4S LiFePO₄ 10 Ah pack + buck converters | 3 | GS-007 station power | $270 | TO ORDER | — |
| 12 | Surveyor tripod + leveling head + sighting rail | 3 | GS-004 survey/heading | $300 | TO ORDER | — |
| 13 | Weatherproof case, 74HC14s, corner-reflector foil, checkerboard print | 3 + misc | GS-006 enclosures, calibration targets | $120 | TO ORDER | — |
| 14 | Breadboard, jumpers, headers | kit | bench | $0 | **OWNED** (theremin) | — |

**Total to order: ≈ $1,650–2,010** (owned lines excluded) — consistent
with lesson 16's ~$2k order of magnitude. Costliest line is cameras
(#4); the lesson's rolling-shutter warning is the reason.

**Note A — FPGA board decision (maiden33 outcome).** The maiden33/35
audit is already in: the behavioral 512-pt FFT synthesizes to ~139k
LUT4s — far over hx8k even after the planned BRAM-explicit rewrite it
may not fit. Pre-empting the ECP5 escape hatch per the card's option:
**ULX3S 85F ×3 (~$540)** is the recommended line; final call at maiden36
bench bring-up per the audit note (results/design-notes/decimation-audit.md).

**Note B — camera model selection.** Global shutter + hardware strobe
out + USB3 + C/CS mount for the three lens fields (60°/35°/60° per D6).
Shortlist at order time; record the chosen model and datasheet link here.
