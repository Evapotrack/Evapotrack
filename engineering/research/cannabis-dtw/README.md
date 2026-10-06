# Cannabis drain-to-waste test of the Next recommendation (2026-10-06)

**Question:** if a cannabis grower using coco or drip drain-to-waste logged every watering in EvapoTrack and poured the app's **Next**, how close would they get to their runoff goal? This is answered for the live app (v1.1) and for revision 2.

**Files** (see also `odd_cases.py` and `odd_cases_results.txt`, the unusual-watering test described in `engineering/plans/2026-10-06-use-cases-and-odd-cases.md`):
- `simulate.py`: the test (`python3 simulate.py`, about 15 s).
- `results.txt`: its output.
- `example-grow-C1.csv`: 91 days of logs, exactly as a grower would type them into the app (revision 2 run). The extra `plant_used_L` column is what the plant really drank, which the app never sees.

## Why the data is simulated, and what it is anchored to

There is no public, watering-by-watering cannabis log with every input the app needs: water added, runoff collected, time between waterings, pot, medium and capacity. Grower forums give rules of thumb, and research papers give totals. The research sites were also blocked from this environment, so the figures below come from search-result summaries of those sources. The grows are therefore **built from published figures**, then run through the app's exact formulas.

| Input | Value used | Source |
|---|---|---|
| Daily water use | Veg 0.5–1.5 L/plant/day; flower 1–3 L/plant/day | Water-use summaries in search results for the greenhouse lighting / water-use-efficiency study (Cannabis sativa, PMC11190854) and grower guides |
| Research drip | 250–650 mL/pot/day, 3.45 L pots, 30% drainage, 1 dripper per pot | Bernstein lab (Volcani Institute) medical cannabis studies, as cited in search results |
| Runoff goal | 10–20% per watering (default 15%) | University of Florida guidance cited by grower guides; Rio Coco recommends 15–20% |
| Drip systems | Judge runoff on the **daily total**, not per shot | Rio Coco watering guide |
| Coco water-holding capacity | 55–65% by volume (60% common) | Product specifications (FloraFlex LooseFill 60% WHC; others 65%) |
| Max Retention Capacity | 3 gal coco/perlite 6.0 L; 3 gal coco 6.8 L; 5 gal coco 11.4 L; 5 gal coco/perlite 10.0 L | EvapoTrack's own reference table (`docs/reference.html`), which matches the capacity figures above |
| Hand watering, 3 gal | e.g. 750 mL in, 75–150 mL runoff for small plants; daily in flower | Grower guides (GrowWeedEasy forum, Modern Farms coco guide) |
| Climate | Veg 26 °C / 65% RH; flower 25 °C / 55→50%; late flower 24 °C / 45% | Common VPD guidance (0.4–0.8 kPa early veg, rising in flower). Logged as the app does, but the recommendation doesn't use it |

**Physical model, per pot:**
- **Deficit:** the plant uses water continuously, creating a deficit.
- **Watering:** fills the deficit, and the rest runs off.
- **Channeling:** in dry coco, 0–3% of the water runs straight through. This is why a little runoff doesn't prove the pot is full.
- **Carry-over:** water not supplied stays owed until the next watering.
- **Dry limit:** the deficit can't exceed 60% of capacity. Reaching it is counted as a "dry" event: the plant ran out of water.

**Grower model:**
- Pours the app's Next, rounded to 50 mL (jug markings).
- Reads runoff to about ±10 mL.
- When the app shows no Next, repeats the last amount.
- The sensitivity check also tries a grower who keeps pouring until runoff appears, and coco that doesn't channel.

## Grows tested

| ID | Setup | Why it's included |
|---|---|---|
| C1 | Photoperiod, coco/perlite 70/30, 3 gal fabric, hand-watered daily, 4 wk veg + 9 wk flower | The most common home setup |
| C2 | Autoflower, coco 100%, 3 gal, daily, 11 weeks | Fast growth from a tiny seedling |
| C3 | Coco 100%, 5 gal, every 2 days in veg then daily in flower | A schedule change mid-grow |
| C4 | Research-style drip: coir 3.45 L pots, one daily irrigation, 30% drainage goal | Published research parameters |
| C5 | Automated drip, 2 gal coco/perlite, 4 shots a day, logged **per day** vs **per shot** | "Hydro-style" drain-to-waste |
| C6 | Water-when-light (lift test), 5 gal coco/perlite, interval 1–4 days | Common hand-watering habit |
| C7 | Daily, but Saturdays skipped plus 10% random skips, 3 gal | Real life |

Recirculating hydroponics (DWC/RDWC) is **not** drain-to-waste and has no runoff to log, so the app doesn't apply to it.

## Results (200 runs per grow)

*In range* means runoff within ±5 points of the goal. *Dry* is the average number of days per grow the plant hit the dry limit.

| Grow | v1.1: in range | v1.1: zero runoff | v1.1: dry days | Rev 2: in range | Rev 2: zero runoff | Rev 2: dry days | Rev 2: water vs ideal |
|---|---|---|---|---|---|---|---|
| C1 photoperiod 3 gal daily | 1.8% | 19.2% | 57 | **61.1%** | 0.3% | 0 | 99% |
| C2 autoflower 3 gal daily | 0.0% | 39.7% | 59 | **54.2%** | 4.6% | 0 | 99% |
| C3 5 gal, schedule change | 0.0% | 18.3% | 71 | **47.4%** | 3.8% | 7.8 | 97% |
| C4 research drip, 30% goal | 22.1% | 0.0% | 0 | **65.4%** | 0.0% | 0 | 98% |
| C5 drip, logged as daily totals | 45.8% | 0.2% | 0 | **71.4%** | 0.0% | 0 | — |
| C5 drip, logged per shot | 29.4% | 16.7% | 0 | 11.2% | 13.2% | 0 | — |
| C6 water-when-light | 0.0% | 17.9% | 47 | **31.6%** | 6.4% | 12 | 97% |
| C7 irregular, skipped days | 0.7% | 21.4% | 71 | **14.4%** | 9.1% | 14 | 88% |

**Sensitivity:** the conclusions hold in every variant.
- **Without channeling:** v1.1 falls into the zero-runoff spiral (90–100% of waterings with no runoff), and revision 2 is unchanged.
- **With a grower who keeps pouring until runoff appears:** v1.1 improves only slightly, because dry coco channels a little water early and the grower stops too soon.

## What this means

1. **The live v1.1 recommendation doesn't work for a growing cannabis plant** if followed as shown. Its all-time average anchors Next to the seedling's small waterings:
   - In C1, a strict follower pours 1.55–1.75 L/day from week 9 to harvest, while the plant uses 1.8–2.6 L.
   - Runoff stays at 0–4%, and the pot hits the dry limit on most days.

   This confirms finding ALG-1 of the September engineering review with cannabis-specific numbers. Real growers would notice wilting and override the app, which is exactly the trust the app is meant to earn.
2. **Revision 2 tracks the plant** for daily hand-watering (C1, C2), research drip (C4) and drip logged as daily totals (C5):
   - Runoff is within ±5 points of the goal on 54–71% of waterings, and almost never zero.
   - The plant never runs dry, and it uses about 99% of the ideal water.

   Late in flower, as the plant drinks less, runoff drifts to 17–20%: slightly generous, which is the safe side.
3. **Three real-world limits**, each with a fix that needs no algorithm change:
   - **Drip users must log one entry per day with daily totals** (C5: 71% in range, vs 11% logging each shot). Per-shot retained water swings with time of day, which no per-watering model can follow. Fix: How To and website guidance.
   - **Skipping a day in peak flower runs a 3 gal pot dry whatever the app says** (C7): two days of use (about 5 L) exceeds what the pot can hold back. Fixes:
     - guidance: water daily in flower, or use a bigger pot;
     - for 1.3: a note on the dashboard when the last watering came after a longer-than-usual gap.

     The note shouldn't change the number, because C6 shows that "water when light" growers also have varying intervals, and scaling by time would over-water them.
   - **Water-when-light growers vary the dryness they water at** (C6, ±15%), which limits any recommendation (32% in range). Fix: guidance to water at a consistent dryness, which is already decision A7.
4. **The `a_up` 0.7 variant** adds 1–6 points in range for C1, C2 and C6, but more >2× runoff for C3, C6 and C7. This matches the earlier finding: a trade, so it stays deferred to 1.3.

## Using it with real data

The best test is a real grow:
1. Export a grow from the app (open the grow › gear icon › Download Data).
2. A cloud session can replay it log by log, showing what each version's Next would have been at every watering compared with what actually happened.
