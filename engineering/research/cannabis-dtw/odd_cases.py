"""
Odd real-world waterings, and how each recommendation recovers from them.

Grow: C1 from simulate.py (photoperiod cannabis, 3 gal fabric pot of amended
coco, hand-watered daily, Max Retention Capacity 6.0 L, goal 15%).
- One unusual watering happens on day 55, in peak flower (the plant uses about 2.4 L/day).
- Physics as in simulate.py, plus fabric-pot channeling: when the medium is
  nearly bone-dry, it shrinks from the fabric wall, and 35-50% of the water runs
  down the gap and out before the root ball absorbs it.

Reported for the 6 waterings after the event, against the same seed with no event:
- the runoff the grower actually gets;
- waterings with no runoff;
- days the plant hits the dry limit;
- waterings until runoff is back within the goal +/-5 points for 2 waterings in a row.

Note: under v1.1 the C1 pot is already at the dry limit well before day 55
(v1.1 under-waters a growing plant), so its rows mostly repeat the reference
row. That is itself a finding: in a fabric pot, chronic under-watering shows up
as HIGH runoff (water channels past dry coco), not low runoff.

Run: python3 odd_cases.py   (about 20 seconds). Writes odd_cases_results.txt.
"""
import os, random, statistics as st, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from simulate import GROWS, ENGINES  # noqa: E402

GROW = GROWS[0]
EVENT_DAY = 55
SEEDS = 200

EVENTS = {
    'none': 'No event (reference)',
    'overpour': 'Accidental overpour: 2x Next poured, pot was not dry (runoff about 55%)',
    'bone_dry': 'Pot went bone-dry (2 days skipped), then Next poured: water channels down the fabric wall',
    'bone_dry_overpour': 'Bone-dry pot, then 2x Next poured in a hurry (runoff often 60%+)',
    'bone_dry_excluded': 'Bone-dry pot, Next poured, log marked "water ran straight through" and left out of Next',
    'bone_dry_rescue': 'Bone-dry pot, re-wet slowly in passes until runoff appears (about 5% channels), total logged',
    'saucer_overflow': 'Saucer overflowed: only half the runoff was measured',
    'forgot_runoff': 'Overpoured 2x and forgot to collect runoff: typed 0',
    'forgot_runoff_excluded': 'Same, but logged as "runoff not measured" and left out of Next',
    'flush': 'Salt flush right after a normal watering: 15 L poured, about 14.9 L runoff, logged',
    'unit_slip': 'Unit slip: values typed in liters while the app was set to mL (logged 1000x too small)',
    'undercollect_all': 'Fabric pot: 15% of runoff escapes the saucer at every watering (whole grow)',
}

def run(engine, seed, event):
    rng = random.Random(seed)
    mrc, goal = GROW['mrc'], GROW['goal']
    cap = 0.6 * mrc
    deficit, logs, last_w = 0.0, [], None
    true_rp, dry_days = [], []
    for day in range(GROW['days']):
        deficit += GROW['et'][day] * (1 + rng.uniform(-0.08, 0.08))
        if deficit > cap:
            deficit = cap; dry_days.append(day)
        skip = event.startswith('bone_dry') and day in (EVENT_DAY - 2, EVENT_DAY - 1)
        # Draw the random numbers in the same order on every path, so runs stay comparable.
        u_bypass, u_read, u_chan = rng.uniform(0, 0.03), rng.uniform(-0.01, 0.01), rng.uniform(0.35, 0.50)
        if skip: continue
        nxt = engine(logs, mrc, goal) if logs else None
        w = GROW['first'] if not logs else (last_w if nxt is None else nxt)
        w = max(0.05, round(w / 0.05) * 0.05)
        ev = day == EVENT_DAY
        if ev and event in ('overpour', 'bone_dry_overpour', 'forgot_runoff'):
            w = round(2 * w / 0.05) * 0.05
        # Fabric-pot channeling when nearly bone-dry, otherwise normal 0-3% bypass.
        chan = u_chan if deficit >= 0.9 * cap else u_bypass
        if ev and event == 'bone_dry_rescue':
            # Slow passes let the coco swell back to the wall; the grower keeps going until about 12% runs off.
            chan = 0.05
            w = max(w, round(deficit / (1 - chan) / 0.88 / 0.05) * 0.05)
        absorbed = min(w * (1 - chan), deficit)
        deficit -= absorbed
        true_r = w - absorbed
        r = 0.0 if true_r < 0.005 else min(w, max(0.0, round(true_r, 2) + u_read))
        if event == 'undercollect_all': r = round(r * 0.85, 2)
        logged_w, logged_r = w, r
        if ev and event == 'saucer_overflow': logged_r = round(r * 0.5, 2)
        if ev and event == 'forgot_runoff': logged_r = 0.0
        if ev and event == 'unit_slip': logged_w, logged_r = w / 1000, r / 1000
        excluded = ev and event in ('bone_dry_excluded', 'forgot_runoff_excluded')
        if not excluded:
            logs.append((logged_w, logged_r))
        last_w = w
        true_rp.append((day, 100 * true_r / w))
        if ev and event == 'flush':
            fw = 15.0
            absorbed = min(fw, deficit); deficit -= absorbed
            fr = fw - absorbed
            logs.append((fw, round(fr, 2)))
    return true_rp, dry_days

def after(true_rp, n=6):
    return [rp for d, rp in true_rp if d > EVENT_DAY][:n]

def recovery(true_rp, goal=15):
    seq = [rp for d, rp in true_rp if d > EVENT_DAY]
    for i in range(len(seq) - 1):
        if abs(seq[i] - goal) <= 5 and abs(seq[i + 1] - goal) <= 5:
            return i + 1
    return len(seq)

def main():
    out = []; p = out.append
    p(f"Odd waterings on day {EVENT_DAY} (peak flower), C1: 3 gal fabric, amended coco, MRC {GROW['mrc']} L, goal {GROW['goal']}%. {SEEDS} runs each.")
    p("Columns, for the 6 waterings after the event:")
    p("  event runoff = true runoff of the event watering; next-6 avg/min/max = true runoff afterwards;")
    p("  zero = waterings with no runoff (of 6); dry = days at the dry limit in the following week;")
    p("  recover = waterings until 2 in a row are within goal +/-5.")
    p("For 'undercollect_all', the figures cover the whole grow.")
    for key, desc in EVENTS.items():
        p('')
        p(f"{key}: {desc}")
        p(f"    {'engine':18s} {'event runoff':>12s} {'next-6 avg':>10s} {'min':>6s} {'max':>6s} {'zero':>5s} {'dry':>5s} {'recover':>8s}")
        for name, eng in list(ENGINES.items())[:2]:
            ev_rp, avg6, mn6, mx6, zero6, dry7, rec = [], [], [], [], [], [], []
            for seed in range(SEEDS):
                trp, dry = run(eng, seed, key)
                if key == 'undercollect_all':
                    seq = [rp for d, rp in trp if d >= 3]
                    avg6.append(st.mean(seq)); mn6.append(min(seq)); mx6.append(max(seq))
                    zero6.append(sum(x < 0.5 for x in seq)); dry7.append(len(dry))
                    rec.append(100 * sum(abs(x - 15) <= 5 for x in seq) / len(seq)); ev_rp.append(float('nan'))
                    continue
                e = [rp for d, rp in trp if d == EVENT_DAY]
                ev_rp.append(e[0] if e else float('nan'))
                a = after(trp)
                avg6.append(st.mean(a)); mn6.append(min(a)); mx6.append(max(a)); zero6.append(sum(x < 0.5 for x in a))
                dry7.append(sum(EVENT_DAY < d <= EVENT_DAY + 7 for d in dry)); rec.append(recovery(trp))
            evs = [x for x in ev_rp if x == x]
            ev_txt = f"{st.mean(evs):10.0f}% " if evs else f"{'(whole grow)':>12s}"
            rec_txt = f"{st.mean(rec):7.1f}" if key != 'undercollect_all' else f"{st.mean(rec):5.0f}% in range"
            p(f"    {name:18s} {ev_txt} {st.mean(avg6):9.1f}% {st.mean(mn6):5.1f}% {st.mean(mx6):5.1f}% {st.mean(zero6):5.2f} {st.mean(dry7):5.2f} {rec_txt}")
    text = '\n'.join(out)
    open(os.path.join(HERE, 'odd_cases_results.txt'), 'w').write(text + '\n')
    print(text)

if __name__ == '__main__':
    main()
