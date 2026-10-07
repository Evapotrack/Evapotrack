# Who EvapoTrack is for, what a real pot holds, and the odd waterings (2026-10-06)

This extends the decisions in [`2026-10-06-decisions.md`](2026-10-06-decisions.md) with three things:
1. The physics of a typical pot: a 3 gal fabric pot of amended coco.
2. The real-world uses where measuring water in and runoff out matters.
3. A test of the unusual waterings real growers make: overpouring above 50% runoff, a bone-dry fabric pot, forgotten runoff, flushes and unit mix-ups.

Simulation code and output are in `engineering/research/cannabis-dtw/` (`odd_cases.py`, `odd_cases_results.txt`).

---

## 1. A 3 gal fabric pot of amended coco, by the numbers

Example recipe: 70% coco, 20% perlite, 10% worm castings, plus a small amount of dry amendments.

| Quantity | Value | Basis |
|---|---|---|
| Nominal volume | 11.4 L (3 US gal) | — |
| Medium actually in the pot | **about 10–10.5 L** (filled 1–2 cm below the rim) | Usual fill |
| Coco needed | About 7 L expanded, from **about 0.55–0.65 kg of compressed brick** | A 5 kg brick expands to about 55–65 L |
| Dry weight of the mix | **About 1.0–1.6 kg** | Coco 0.06–0.10 g/cm³, perlite 0.03–0.15, castings about 0.5 |
| Water while fully saturated (still dripping) | About 8–9 L | Total porosity 80–90% |
| **Water held after it stops draining** (container capacity) | **About 4.5–5.8 L (≈ 5.5 L typical)** | Coco water-holding capacity 40–59%; perlite lowers it, castings raise it. The app's reference table says 6.0 L for a full 11.4 L pot of 70/30 coco/perlite |
| Air space after draining | About 20–35% | Coco air-filled porosity 13–30%, plus perlite |
| **Usable water before the plant is stressed** | **About 2.5–3 L** (roughly half of what it holds) | Growers water when the pot feels about half as heavy in water |
| Pot weight, just watered and drained | About 7.5–8 kg (16–17.5 lb), with the plant | Medium + water + pot + plant |
| Pot weight, time to water (lift test) | About 4.5–5 kg (10–11 lb) | — |
| Pot weight, bone-dry | About 2–2.5 kg | — |
| **Most one watering can put into the pot** | **Whatever the pot has lost since it was last full**, at most about 3.5 L | Everything above that runs off |

**Daily water use of one photoperiod cannabis plant in this pot** (one plant per about 2×2 ft, indoor light):

| Stage | Litres per day | Notes |
|---|---|---|
| Clone or seedling just transplanted | 0.1–0.3 | Roots haven't reached the pot walls |
| Early veg | 0.3–0.6 | — |
| Late veg | 0.6–1.3 | Published range: 0.5–1.5 L/day in veg |
| Stretch (flower weeks 1–3) | 1.3–2.2 | Fastest rise |
| Bulking (flower weeks 4–7) | 2.0–2.8, up to about 3–4 under strong light | Published range: 1–3 L/day in flower; peak demand is about **1 L per sq ft of flowering canopy per day** |
| Ripening (last 2–3 weeks) | Falls 20–35% | — |
| Fabric-pot extra | +10–25% vs plastic | Fabric walls lose water 2–3× faster than plastic pots |

**What this means in practice:**
- **In peak flower, the plant uses about as much water in a day as the pot can give before stress** (2.5–3 L). A 3 gal pot must be watered every day in flower, sometimes twice. Skipping a day empties it.
- **An accidental big pour can't overfill the pot.** For example, pouring 5.6 L when the pot is down 2.4 L sends 3.2 L out as runoff (57%). The pot still holds only what it lost.
  - **In coco:** harmless to the plant; about 3 L of nutrient solution wasted.
  - **In amended coco:** washes out some soluble amendments. Amended-coco growers often aim lower (goal 5–10%, inside the app's 5–50% range).

## 2. Who measures water in and runoff out: the app's real niche

| Tier | Grower | Why they measure runoff | Fit |
|---|---|---|---|
| **Core** | **Home cannabis/hemp growers in coco, coco/perlite or soilless mixes**: hand-watered drain-to-waste, or automated drip logged as daily totals | 10–20% runoff every watering to stop salt build-up; they already collect and test runoff (EC and pH) | **Best.** The protocol is exactly the app's |
| **Core** | **Hobby vegetable and fruit growers in soilless containers**: chili peppers in coco, tomatoes, cucumbers and strawberries in grow bags or Dutch buckets | Chili-grower guides say water to about 20% runoff each time; greenhouse tomato and cucumber growers target 15–30% drain | **Very good**, same workflow |
| **Strong** | **Small greenhouses and nurseries** checking a leaching fraction on sample pots | Extension guidance: a leaching fraction of 10–20%, checked by collecting leachate in saucers | Good for sample plants (the 30 grows × 25 plants limit suits sampling) |
| **Secondary** | **Container soil, potting-mix and houseplant keepers** who water until it drains | Extension guidance: water until it runs out the bottom, and leach salts every few months | Useful for learning what a pot drinks; most won't measure every time |
| **Not a fit** | Living or no-till soil (growers avoid runoff); recirculating hydro (DWC, RDWC, NFT: no runoff); self-watering and bottom-watered pots; in-ground beds | No drain-to-waste runoff to measure | Say so in the help so expectations are right |

**Implications:**
- **Positioning (extends A11):** describe EvapoTrack by **medium and method** ("coco, perlite, rockwool, peat mixes, soil; drain-to-waste; runoff %"), never by crop. That covers every core tier and stays App Store-safe.
- **Defaults fit the niche:** the 15% default goal and the 5–50% range match leaching-fraction (10–20%), greenhouse (15–30%) and research (30%) practice. Amended coco at 5–10% also fits.
- **The biggest missing feature for the core niche is runoff EC and pH.** These growers already measure both when they collect runoff. Caveat: in coco, runoff EC reads higher than the root zone, so the app should show trends rather than judge single readings. This needs a data-model change (a new schema version), so it belongs in a later version (A16).

## 3. Odd waterings: what happens and what to do

The test uses grow C1 (3 gal, coco, daily, goal 15%). One unusual watering happens in peak flower, then the next 6 waterings are followed (200 runs). It adds **fabric-pot channeling**: when the pot is nearly bone-dry, the coco shrinks from the wall, and 35–50% of the water runs down the gap and out.

Results are for revision 2. Under v1.1 the pot is already at the dry limit by then, because v1.1 under-waters a growing plant; that is itself the first finding below.

| Event | What the grower sees | Revision 2 afterwards | Verdict |
|---|---|---|---|
| **Accidental overpour, 2× Next** (pot not dry) | 57% runoff | Unchanged: back at 15% at once | ✅ **Harmless.** High runoff from a pot that really filled measures the plant's need correctly |
| **Bone-dry fabric pot, Next poured** | 43% runoff, but the plant is dry | Stays at the dry limit; the estimate keeps falling | ❌ **The trap.** Runoff looks high, so both versions lower Next, and the pot never re-wets |
| Same, log left out of Next | 43% runoff | Still stuck | ❌ Leaving it out isn't enough; the pot is still physically dry |
| **Bone-dry, re-wet slowly in passes until runoff appears** | 16% runoff | Recovers in about 5 waterings, never dry | ✅ **The fix is how you water, plus the app noticing** |
| Bone-dry, 2× poured in a hurry | 43% | Recovers in about 7 (runoff up to 31%) | ⚠️ Saved by accident |
| **Saucer overflowed** (half the runoff lost) | 15% | Back on goal in about 3 | ✅ Revision 2 absorbs it |
| **Forgot to collect runoff, typed 0** (after a 2× pour) | — | **About 40% runoff for the next 6 waterings**, about 10 waterings to settle | ⚠️ Wasteful. Marking it "runoff not measured" removes the effect completely |
| **Salt flush** (15 L poured right after watering, logged) | ~99% runoff | Unchanged | ✅ Revision 2 skips it (v1.1 drops Next sharply) |
| **Unit slip** (litres typed with the app set to mL) | — | Dips to about 10% runoff, recovers in about 5 | ✅ Mild. The reverse slip is blocked by the 100 L limit or the over-capacity alert |
| **Fabric pot leaks 15% of runoff past the saucer every time** | — | True runoff averages 16%; 61% of waterings in range | ✅ The bias is on the safe side |

**Finding 1: in a fabric pot, chronic under-watering shows up as *high* runoff, not low.** Dry coco channels water past the root ball. A grower (or an app) reading "43% runoff" as "too much water" makes it worse. Under v1.1, the test pot reaches this state on its own before day 55.

**Finding 2: the app can spot it.** Flag a watering when **runoff is at least twice the goal and the water retained is no more than 75% of the app's Expected amount**. In simulation this:
- caught **92.5%** of channeled waterings;
- raised **no** false alarms on accidental overpours, because a pot that really fills retains its normal amount;
- raised **no** false alarms in normal 91-day grows.

It should be a question to the grower, not an automatic exclusion.

---

## 4. New recommendations

| # | Recommendation | Version | Evidence | Effort |
|---|---|---|---|---|
| **A12** | **"Collecting runoff" guidance** in How To and on the website, EN and ES: <br>• Use a saucer wider than the pot. <br>• Wait until dripping stops (10–30 min), then measure and empty it. <br>• Never let the pot sit in runoff. <br>• **Don't let fabric pots go bone-dry. If one does, water slowly in passes until runoff appears, then log the total.** | 1.2 (text only) | The bone-dry trap and its fix | Small |
| **A13** | **"Leave out of Next" option on a watering**, with reasons: runoff not measured / salt flush / water ran straight through. The log stays in History and the export, but isn't used for the estimate | 1.2 (moved from 1.3 by the 2026-10-07 plan) | Forgotten runoff: about 40% runoff for 6 waterings → none. It also gives growers control over flushes and channeling | Medium (a new stored field, so a schema version) |
| **A14** | **Channeling check:** when runoff ≥ 2× goal and retained ≤ 75% of Expected, ask *"Did water run straight through a dry pot?"*, show the re-wet steps, and offer A13 | 1.3 | 92.5% caught, 0 false alarms in simulation | Small, on top of A13 |
| **A15** | **Check-the-unit hint** in the over-capacity alert: add "and the unit (mL, L or gal)" to "Check Water Added and Runoff" | 1.2 (text only) | Catches the unit slip that does get past validation | Tiny |
| **A16** | **Optional runoff EC and pH** per watering, shown as trends | Later (1.4) | The core niche already measures them; coco runoff reads high, so trends only | Medium–large |
| **A17** | **Research the weight method**: pot weight before watering vs after draining gives retained water directly, with no runoff collection (useful for fabric pots) | Research | Physics in §1: the weight difference equals the water retained | Research first |
| **A18** | **Max Retention Capacity guidance**: the reference table assumes a completely full pot; suggest about 90% of the table value for normal fills (3 gal amended coco ≈ 5.5 L) | 1.2 (text only) | §1 | Tiny |

**Positioning:** describe the app by medium and method, not crop (extends A11). The help should also say plainly who it is *not* for: living soil, recirculating hydro, self-watering pots.

## Sources

- Coco and container physics:
  - [HortiDaily: features of greenhouse growing media](https://www.hortidaily.com/article/6012310/the-essential-features-of-greenhouse-growing-media/)
  - [INIFAP: physical characterization of substrates](https://cienciasagricolas.inifap.gob.mx/index.php/agricolas/article/view/4117)
  - [NC State: container media properties](https://hortscans.ces.ncsu.edu/uploads/c/o/componen_51a50d5fae05b.pdf)
  - [FloraFlex LooseFill coco (60% water-holding capacity)](https://hydrobuilder.com/products/floraflex-buffered-loosefill-coco-coir-60-whc)
  - Coco brick expansion: [Urban Worm coco 5 kg](https://pepperjoe.com/es/products/urban-worm-coco-coir-5kg) and [Reptilian Arts 10 lb brick](https://reptilianarts.com/products/coco-coir-compressed-brick-10-lb)
- Fabric pots:
  - [Smart Pots / HortScience: fabric containers](https://smartpots.com/wp-content/uploads/2023/10/HortScience-Fabric-Containers.pdf)
  - [ASHS: container type affects irrigation requirement](https://ashs.confex.com/ashs/2014/webprogram/Paper18406.html)
  - [Garden Myths: fabric vs plastic pots](https://www.gardenmyths.com/fabric-pots-plastic-pots/)
  - [Journeyman: fabric pots and moisture](https://www.journeymanhq.com/?p=718310)
- Water use:
  - [Greenhouse Grower: calculating cannabis water use](https://www.greenhousegrower.com/?p=157955)
  - [PMC11190854: lighting and cannabis water use](https://pmc.ncbi.nlm.nih.gov/articles/PMC11190854)
  - [Ganjier: cannabis water use](https://www.ganjier.com/2021/06/14/a-reconsideration-of-cannabis-water-use/)
- Leaching fraction and drain targets:
  - [UF/IFAS EP529: leaching fraction](https://edis.ifas.ufl.edu/publication/EP529)
  - [Nursery Management: pour-through guide](https://nurserymag.com/article/nm0313-pour-through-extraction-guide)
  - [WUR: greenhouse substrate drain](https://edepot.wur.nl/403806)
  - [PMC9573875](https://pmc.ncbi.nlm.nih.gov/articles/PMC9573875)
- Hobby growers: [THP: growing peppers in coco](https://thehotpepper.com/threads/a-guide-to-growing-peppers-in-coco-coir.59291/page-2)
- Houseplants:
  - [UMD Extension: watering indoor plants](https://www.extension.umd.edu/resource/watering-indoor-plants)
  - [UCANR: leach your houseplants](https://ucanr.edu/blog/stanislaus-sprout/article/leach-your-houseplants-avoid-salt-problems)
- Runoff EC and pH:
  - [CANNA: measuring coco](https://www.canna.com.au/measuring_coco)
  - [FloraFlex: salt build-up in coco vs rockwool](https://floraflex.com/EU/blog/post/salt-buildup-coco-rockwool-dryback-fix)
