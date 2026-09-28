# Next-recommendation model study

This study chose the model used by `Evapotrack/Services/RecommendationEngine.swift`.

## Method

It is a closed-loop simulation (`study.py`). Each watering, the medium has a true deficit **D**: the volume it absorbs before free drainage starts. The simulated grower adds the amount Next recommends. Runoff is `max(0, W − D)` plus a small reading error. When runoff is above 0, retained equals D (a measurement). When runoff is 0, retained equals W, which is at most D (censored, only a lower bound). Each candidate estimates D from the history so far, and `Next = min(D̂, MRC) / (1 − goal)`, capped at 100 L. The goal is 15%.

Metrics use 200 seeds × 30 waterings per scenario:

| Metric | Meaning |
|---|---|
| mean / med | Mean and median distance of actual runoff % from the 15% goal, in percentage points |
| zero% | Share of waterings with no runoff (the plant got less than it needed) |
| >30% | Share of waterings with runoff above 2× goal (wasted water) |
| over / under | Share more than 5 pp above or below the goal |
| conv | Median waterings until runoff is back within ±5 pp of the goal after a bad start (S1b), a 35% drop (S6) or a step change (S11) |

## Files

| File | Purpose |
|---|---|
| `study.py` | Round 1: physical model, 18 scenarios, first candidate families A–G, metrics → `results.json` |
| `round2.py` | Round 2: EWMA and Holt variants with a clip on downward moves; top-up skip → `results2.json` |
| `round3.py` | Round 3: extended scenarios (S8b, S9b, S7b, S12, S13) and full Holt with clip → `results3.json` |
| `round4.py` | Round 4: trend-cap and damping grid, EWMA vs Holt → `round4_output.txt` |
| `engine_ref.py` | Python port of the shipped Swift engine, line for line |
| `expectations.py` | Expected values used in `RecommendationEngineTests.swift` |
| `final_table.py` | Current model vs shipped engine over all scenarios → `final.json`, `final_table_output.txt` |
| `early/sim.py`, `early/alt.py` | First exploratory ports of the old algorithm, used during the audit |

Run any script from this folder, for example `python3 final_table.py`. A full run takes a few minutes. The scripts are seeded, so the results are reproducible.

## Result

The shipped model is a Holt level with a damped trend (α 0.5, β 0.2, φ 0.8), using no-runoff waterings as lower bounds, skipping full runoff, with at most a 25% drop per watering and the trend capped at ±25% of the level.

| Average over 18 scenarios | Current model | Shipped engine |
|---|---|---|
| Mean distance from goal (pp) | 9.9 | 6.2 |
| Zero-runoff waterings | 34.4% | 9.7% |
| Runoff above 2× goal | 7.2% | 4.5% |
| Convergence: bad start / 35% drop / step | 14 / 30 / 30 | 5 / 6 / 5 |

The engine costs more in some scenarios: with heavy stationary noise (S7, S7b) and irregular intervals (S8), it has more waterings above 2× goal, because it reacts to changes the old all-time mean ignored. See `final_table_output.txt` for every scenario.
