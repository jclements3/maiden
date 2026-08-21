# maiden30 — Order the hardware [desk]

**Sprint goal.** Every part the hardware track (sprints 31–48) needs is
chosen, priced, committed as a BOM, and ordered.

**Depends on.** None (do this around the time you start maiden09, so parts
arrive before maiden31 — per maiden00 "Reading the split").

**Read first.** lesson16.md § "The shopping list (lessons 16–21)", § "Doppler
arithmetic, one more time" (so the band choice behind the module quantities
is understood, not copied).

## Tasks

- [ ] Inventory what you already own against the lesson 16 table (two
      HB100s, iCEstick, HX8K breakout from the theremin course) and strike
      those lines.
- [ ] Decide camera model + the three lenses (60°/35°/60° per D6) — the
      one line the lesson says not to cheap out on; confirm global shutter
      and strobe output in the datasheet before ordering.
- [ ] Decide the FPGA board line now or defer: read lesson 17's hx8k
      budget discussion; if you pre-empt the ECP5 escape hatch, order ULX3S
      and note the decision for the maiden33 audit.
- [ ] Pick the ADC for the lesson 17 chain (MCP3202-class per lesson 17
      Build 5) and add it — it is not a separate table line; don't miss it.
- [ ] Write `hardware/BOM.md`: item, quantity, vendor, price, which
      requirement it serves (crib the "For" column), order date, and a
      status column you'll update on arrival.
- [ ] Place the orders; record order numbers/ETAs in the BOM.
- [ ] Commit the BOM.

## Done when

- `hardware/BOM.md` is committed, covers every line of lesson 16's table
  plus the ADC, and every line is marked owned / ordered with an ETA.
- Total spend is recorded and roughly matches the lesson's ~$2k order of
  magnitude (a large deviation means a missed or duplicated line — audit
  before accepting it).

## Doc trace

GS-001–GS-007, AB-001, SYS-006 (parts allocation per BOM); D6 parts
choices; D5 risk R2 (module A/B stock: CDM324 ×3+1 *and* the owned HB100s
travel to VT-05).
