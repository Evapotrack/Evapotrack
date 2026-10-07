"""
Cannabis drain-to-waste grows replayed through EvapoTrack's recommendation, as if
a grower logged every watering in the app and then poured the app's Next amount.

Why simulated: no public watering-by-watering cannabis log with every input the
app needs (water added, runoff, interval, pot, medium, capacity) could be found.
The grows below are built from published figures instead (see README.md):
- daily water use: 0.5-1.5 L/plant/day in veg and 1-3 L in flower;
- research drain-to-waste coir: 250-650 mL/pot/day at 30% drainage in 3.45 L pots;
- coco water-holding capacity 55-65%, and the app's own reference table for
  Max Retention Capacity;
- a 10-20% runoff target, and drip systems judged on daily totals.

Physical model, per pot:
- The plant uses water continuously, creating a deficit.
- A watering fills the deficit, and the rest runs off.
- In dry coco, 0-3% of the water channels straight through.
- Water not supplied stays owed until the next watering (carry-over).
- The deficit can't exceed 60% of capacity; reaching it counts as a "dry" event
  (the plant ran out of water).

Grower model:
- Pours the app's Next rounded to 50 mL, and reads runoff to about +/-10 mL.
- When the app shows no Next, repeats the last amount.

Engines:
- legacy  = v1.1 exactly (WateringCalculationService + PlantDashboardViewModel).
- rev2    = revision 2's RecommendationEngine (engine_var with a_up = 0.5 is
            identical to engine_ref.py).
- rev2+   = the a_up = 0.7 variant (information only).

Also runs a sensitivity check: a grower who keeps pouring until runoff appears,
and coco that does not channel.

Run: python3 simulate.py   (about 15 seconds). Writes results.txt and
example-grow-C1.csv next to this file.
"""
import csv, math, os, random, statistics as st, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), 'algorithm', '2026-10-06-asymmetric-check'))
import engine_var  # noqa: E402

SEEDS = 200

# ---------------------------------------------------------------- engines
def legacy(logs, mrc, goal):
    """v1.1: ((last retained + mean of all retained) / 2) / (1 - goal), capped by MRC/(1-goal);
    nothing shown when the last retained <= 0."""
    if not logs: return None
    ret = [w - r for w, r in logs]
    if ret[-1] <= 0: return None
    f = 1 - goal / 100
    return min(((ret[-1] + sum(ret) / len(ret)) / 2) / f, mrc / f)

def rev2(a_up):
    def f(logs, mrc, goal):
        res = engine_var.recommend([(w, r, i) for i, (w, r) in enumerate(logs)], mrc, goal, a_up)
        return res['next'] if isinstance(res, dict) else None
    return f

ENGINES = {'v1.1 (live)': legacy, 'revision 2': rev2(0.5), 'rev2 + a_up 0.7': rev2(0.7)}

# ---------------------------------------------------------------- grows
def ramp(points, n):
    """Piecewise-linear daily water use (L/day) from (day, value) points."""
    out = []
    for d in range(n):
        for (d0, v0), (d1, v1) in zip(points, points[1:]):
            if d0 <= d <= d1:
                out.append(v0 + (v1 - v0) * (d - d0) / max(1, d1 - d0)); break
    return out

def climate(day, stages):
    for end, t, rh in stages:
        if day < end: return t, rh
    return stages[-1][1], stages[-1][2]

PHOTO_CLIMATE = [(28, 26.0, 65), (49, 25.0, 55), (77, 25.0, 50), (999, 24.0, 45)]
AUTO_CLIMATE = [(21, 25.0, 65), (42, 25.0, 55), (999, 24.0, 47)]

def daily(day): return True

GROWS = [
    dict(id='C1', name='Photoperiod, coco/perlite 70/30, 3 gal fabric, hand-watered daily (4 wk veg + 9 wk flower)',
         mrc=6.0, goal=15, days=91, first=1.0, climate=PHOTO_CLIMATE,
         et=ramp([(0, .5), (27, 1.3), (48, 2.3), (76, 2.6), (90, 1.7)], 91), water_on=daily),
    dict(id='C2', name='Autoflower, coco 100%, 3 gal, hand-watered daily (11 weeks)',
         mrc=6.8, goal=15, days=77, first=0.5, climate=AUTO_CLIMATE,
         et=ramp([(0, .2), (41, 1.8), (62, 2.0), (76, 1.3)], 77), water_on=daily),
    dict(id='C3', name='Photoperiod, coco 100%, 5 gal, every 2 days in veg then daily in flower',
         mrc=11.4, goal=15, days=91, first=1.5, climate=PHOTO_CLIMATE,
         et=ramp([(0, .65), (27, 1.7), (48, 3.0), (76, 3.4), (90, 2.2)], 91),
         water_on=lambda d: d % 2 == 0 if d < 28 else True),
    dict(id='C4', name='Research-style drip, coir 3.45 L pots, one daily irrigation, 30% drainage goal',
         mrc=2.0, goal=30, days=63, first=0.25, climate=PHOTO_CLIMATE,
         et=ramp([(0, .175), (62, .455)], 63), water_on=daily),
    dict(id='C6', name='Water-when-light (lift test), coco/perlite 70/30, 5 gal, interval varies 1-4 days',
         mrc=10.0, goal=15, days=91, first=2.0, climate=PHOTO_CLIMATE,
         et=ramp([(0, .65), (27, 1.7), (48, 3.0), (76, 3.4), (90, 2.2)], 91), water_on='when_light'),
    dict(id='C7', name='Irregular: daily but Saturdays skipped (+10% random skips), coco/perlite 70/30, 3 gal',
         mrc=6.0, goal=15, days=91, first=1.0, climate=PHOTO_CLIMATE,
         et=ramp([(0, .5), (27, 1.3), (48, 2.3), (76, 2.6), (90, 1.7)], 91), water_on='irregular'),
]

# ---------------------------------------------------------------- one grow, one engine
def run(grow, engine, seed, keep_log=False, grower='strict', channel=0.03):
    rng = random.Random(seed)
    mrc, goal = grow['mrc'], grow['goal']
    cap = 0.6 * mrc
    deficit, logs, rows, last_w, dry = 0.0, [], [], None, 0
    threshold = None
    for day in range(grow['days']):
        use = grow['et'][day] * (1 + rng.uniform(-0.08, 0.08))
        deficit += use
        if deficit > cap:
            deficit, dry = cap, dry + 1
        mode = grow['water_on']
        if mode == 'when_light':
            if threshold is None: threshold = 0.35 * mrc * rng.uniform(0.85, 1.15)
            water = day == 0 or deficit >= min(threshold, 0.55 * mrc) or deficit >= cap * 0.98
            if water: threshold = 0.35 * mrc * rng.uniform(0.85, 1.15) * min(1.0, 0.45 + day / 60)
        elif mode == 'irregular':
            water = day == 0 or not (day % 7 == 5 or rng.random() < 0.10)
        else:
            water = mode(day)
        if not water: continue
        nxt = engine(logs, mrc, goal) if logs else None
        w = grow['first'] if not logs else (last_w if nxt is None else nxt)
        w = max(0.05, round(w / 0.05) * 0.05)
        bypass = rng.uniform(0.0, channel)
        absorbed = min(w * (1 - bypass), deficit)
        deficit -= absorbed
        true_r = w - absorbed
        if grower == 'to_runoff':
            # A habit many growers have: no runoff seen, so keep adding 10% until some appears (up to 5 times).
            step = 0.05 * max(1, round(0.1 * w / 0.05))
            for _ in range(5):
                if true_r >= 0.005: break
                add = min(step, 100 - w)
                got = min(add, deficit); deficit -= got
                w += add; true_r += add - got
        r = 0.0 if true_r < 0.005 else min(w, max(0.0, round(true_r, 2) + rng.uniform(-0.01, 0.01)))
        logs.append((w, r)); last_w = w
        if keep_log:
            t, rh = climate(day, grow['climate'])
            rows.append(dict(day=day + 1, water_added_L=round(w, 2), runoff_L=round(r, 2), retained_L=round(w - r, 2),
                             runoff_pct=round(100 * r / w, 1), capacity_pct=round(100 * (w - r) / mrc, 1),
                             temp_C=round(t + rng.uniform(-1, 1), 1), humidity_pct=round(rh + rng.uniform(-3, 3)),
                             plant_used_L=round(use, 2)))
    return logs, dry, rows

def score(grow, logs, dry):
    g = grow['goal']
    rp = [100 * r / w for w, r in logs[3:]]
    n = len(rp)
    water = sum(w for w, _ in logs)
    ideal = sum(grow['et']) / (1 - g / 100)
    return dict(inrange=100 * sum(abs(x - g) <= 5 for x in rp) / n, zero=100 * sum(x < 0.5 for x in rp) / n,
                over2x=100 * sum(x > 2 * g for x in rp) / n, err=st.mean(abs(x - g) for x in rp),
                dry=dry, water=100 * water / ideal, n=len(logs))

# ---------------------------------------------------------------- C5: automated multi-shot drip
def run_c5(engine, seed, per_shot):
    """Coco/perlite 70/30, 2 gal (MRC 4.0 L), 12/12 flower, 4 drip shots a day at
    07:00, 10:00, 13:00 and 16:00 (lights 06-18). Use ramps 1.6 -> 2.4 L/day.
    per_shot=False: the grower logs one entry a day with the day's totals and
    splits Next into 4 equal shots. per_shot=True: every shot is logged on its own
    and each shot pours the app's Next."""
    rng = random.Random(seed)
    mrc, goal, cap = 4.0, 15, 2.4
    days = 49
    deficit, logs, dry, last_w = 0.0, [], 0, None
    rp_all = []
    for day in range(days):
        daily_use = (1.6 + 0.8 * day / (days - 1)) * (1 + rng.uniform(-0.08, 0.08))
        hourly = [daily_use * (0.9 / 12 if 6 <= h < 18 else 0.1 / 12) for h in range(24)]
        tot_w = tot_r = 0.0
        if not per_shot:
            nxt = engine(logs, mrc, goal) if logs else None
            day_w = 1.6 if not logs else (last_w if nxt is None else nxt)
            shot_w = max(0.05, round(day_w / 4 / 0.025) * 0.025)
        for h in range(24):
            deficit = min(cap, deficit + hourly[h])
            if deficit >= cap: dry += 1
            if h in (7, 10, 13, 16):
                if per_shot:
                    nxt = engine(logs, mrc, goal) if logs else None
                    w = 0.4 if not logs else (last_w if nxt is None else nxt)
                    w = max(0.025, round(w / 0.025) * 0.025)
                else:
                    w = shot_w
                absorbed = min(w * (1 - rng.uniform(0, 0.03)), deficit)
                deficit -= absorbed
                r = w - absorbed
                r = 0.0 if r < 0.005 else max(0.0, round(r, 2) + rng.uniform(-0.01, 0.01))
                tot_w += w; tot_r += r
                if per_shot:
                    logs.append((w, r)); last_w = w
                    if day >= 3: rp_all.append(100 * r / w)
        if not per_shot:
            logs.append((tot_w, tot_r)); last_w = tot_w
            if day >= 3: rp_all.append(100 * tot_r / tot_w)
    n = len(rp_all)
    return dict(inrange=100 * sum(abs(x - goal) <= 5 for x in rp_all) / n, zero=100 * sum(x < 0.5 for x in rp_all) / n,
                over2x=100 * sum(x > 2 * goal for x in rp_all) / n, err=st.mean(abs(x - goal) for x in rp_all), dry=dry)

# ---------------------------------------------------------------- main
def main():
    out = []
    p = out.append
    p('Closed-loop results: the grower pours the app\'s Next every time. %d runs per grow; the first 3 waterings are not scored.' % SEEDS)
    p('in-range = runoff within goal +/-5 points; zero = waterings with no runoff; >2x = runoff above twice the goal;')
    p('error = mean distance from the goal (points); dry = hours/days the plant hit the dry limit (mean per grow);')
    p('water = water poured as % of the ideal amount (plant use / (1 - goal)).')
    for grow in GROWS:
        p('')
        p(f"{grow['id']}  {grow['name']}  (Max Retention Capacity {grow['mrc']} L, goal {grow['goal']}%)")
        p(f"    {'engine':18s} {'in-range':>8s} {'zero':>6s} {'>2x':>6s} {'error':>6s} {'dry':>5s} {'water':>6s}")
        for name, eng in ENGINES.items():
            s = [score(grow, *run(grow, eng, seed)[:2]) for seed in range(SEEDS)]
            m = lambda k: st.mean(x[k] for x in s)
            p(f"    {name:18s} {m('inrange'):7.1f}% {m('zero'):5.1f}% {m('over2x'):5.1f}% {m('err'):5.1f}  {m('dry'):5.2f} {m('water'):5.0f}%")
    for per_shot, label in ((False, 'one log per day with daily totals'), (True, 'one log per shot')):
        p('')
        p(f"C5  Automated drip, coco/perlite 70/30, 2 gal, 4 shots/day (12/12 flower), logged as {label}")
        p(f"    {'engine':18s} {'in-range':>8s} {'zero':>6s} {'>2x':>6s} {'error':>6s} {'dry h':>6s}")
        for name, eng in ENGINES.items():
            s = [run_c5(eng, seed, per_shot) for seed in range(SEEDS)]
            m = lambda k: st.mean(x[k] for x in s)
            p(f"    {name:18s} {m('inrange'):7.1f}% {m('zero'):5.1f}% {m('over2x'):5.1f}% {m('err'):5.1f}  {m('dry'):5.1f}")

    p('')
    p('Sensitivity (C1 and C2): does the picture change if the grower behaves differently, or coco does not channel?')
    p(f"    {'grow':4s} {'variant':34s} {'engine':18s} {'in-range':>8s} {'zero':>6s} {'>2x':>6s} {'error':>6s} {'dry':>5s} {'water':>6s}")
    for grow in GROWS[:2]:
        for label, kw in (('waters on until runoff appears', dict(grower='to_runoff')), ('no channeling in dry coco', dict(channel=0.0))):
            for name in ('v1.1 (live)', 'revision 2'):
                s = [score(grow, *run(grow, ENGINES[name], seed, **kw)[:2]) for seed in range(SEEDS)]
                m = lambda k: st.mean(x[k] for x in s)
                p(f"    {grow['id']:4s} {label:34s} {name:18s} {m('inrange'):7.1f}% {m('zero'):5.1f}% {m('over2x'):5.1f}% {m('err'):5.1f}  {m('dry'):5.2f} {m('water'):5.0f}%")

    # An in-app replay of C1 (seed 1) for both engines, written as the grower would log it.
    grow = GROWS[0]
    p('')
    p('C1 replay, seed 1: what the grower would type into the app (sampled days)')
    for name in ('v1.1 (live)', 'revision 2'):
        _, _, rows = run(grow, ENGINES[name], 1, keep_log=True)
        if name == 'revision 2':
            with open(os.path.join(HERE, 'example-grow-C1.csv'), 'w', newline='') as fh:
                wr = csv.DictWriter(fh, fieldnames=list(rows[0].keys())); wr.writeheader(); wr.writerows(rows)
        p(f'  {name}')
        p('    day  added  runoff  retained  runoff%  temp  RH   (plant used)')
        for r in rows:
            if r['day'] in (1, 2, 3, 4, 5, 6, 7, 14, 21, 28, 35, 42, 49, 56, 63, 70, 77, 84, 91):
                p(f"    {r['day']:3d}  {r['water_added_L']:5.2f}  {r['runoff_L']:6.2f}  {r['retained_L']:8.2f}  {r['runoff_pct']:6.1f}%  {r['temp_C']:4.1f}  {r['humidity_pct']:3d}%  ({r['plant_used_L']:.2f})")
    text = '\n'.join(out)
    open(os.path.join(HERE, 'results.txt'), 'w').write(text + '\n')
    print(text)

if __name__ == '__main__':
    main()
