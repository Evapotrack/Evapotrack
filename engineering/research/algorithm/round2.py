import random, statistics as st, math, json
import study
from study import G, usable, censored, metrics, scen, N, growth, decline

def ewma_clip(alpha, c_down, c_up=None):
    def upd(s, y):
        lo = s * (1 - c_down)
        hi = s * (1 + c_up) if c_up is not None else float('inf')
        y = min(max(y, lo), hi)
        return alpha * y + (1 - alpha) * s
    return study.smoother(upd)

def holt_clip(alpha, beta, phi, c_down):
    def f(h):
        state = None
        for x in h:
            if usable(x):
                y = x['ret']
                if state is None: state = (y, 0.0); continue
                l, b = state
                pred = l + phi * b
                y = max(y, pred * (1 - c_down))
                nl = alpha * y + (1 - alpha) * pred
                nb = beta * (nl - l) + (1 - beta) * phi * b
                state = (nl, nb)
            elif censored(x):
                state = (x['w'], 0.0) if state is None else (max(state[0], x['w']), max(state[1], 0.0))
        if state is None: return None
        return max(1e-6, state[0] + phi * state[1])
    return f

def ewma_topup(alpha, c_down, ratio=0.4):
    """EWMA + censor + downward clip, and skips 'partial' waterings: interval
    shorter than ratio x median of the previous 5 intervals AND retained below
    60% of the current level."""
    def f(h):
        level, intervals = None, []
        for x in h:
            iv = x['interval_h']
            short = (iv is not None and len(intervals) >= 2 and
                     iv < ratio * st.median(intervals[-5:]))
            if usable(x):
                y = x['ret']
                if level is None: level = y
                elif short and y < 0.6 * level: pass          # partial: ignore
                else:
                    y = max(y, level * (1 - c_down))
                    level = alpha * y + (1 - alpha) * level
            elif censored(x):
                level = x['w'] if level is None else max(level, x['w'])
            if iv is not None and not short: intervals.append(iv)
        return level
    return f

def rate_model(alpha, mode):
    """mode='elapsed': D = rate x time since last watering (known when the
    grower is about to water). mode='typical': D = rate x median recent interval."""
    def f(h, elapsed_h=None):
        rate, intervals, first = None, [], None
        for x in h:
            iv = x['interval_h']
            if iv is None:
                if first is None: first = x['ret'] if usable(x) else (x['w'] if censored(x) else None)
                continue
            intervals.append(iv)
            if usable(x):
                y = x['ret'] / iv
                rate = y if rate is None else alpha * y + (1 - alpha) * rate
            elif censored(x):
                y = x['w'] / iv
                rate = y if rate is None else max(rate, y)
        if rate is None: return first
        if mode == 'elapsed':
            return rate * (elapsed_h if elapsed_h is not None else st.median(intervals[-5:]))
        return rate * st.median(intervals[-5:])
    f.needs_elapsed = (mode == 'elapsed')
    return f

C2 = {
  'A  legacy':                                 study.cand_legacy,
  'C+ EWMA .5 censor':                         study.ewma(0.5),
  'C+ EWMA .5 censor clip down50':             ewma_clip(0.5, 0.5),
  'C+ EWMA .5 censor clip down35':             ewma_clip(0.5, 0.35),
  'C+ EWMA .5 censor clip down25':             ewma_clip(0.5, 0.25),
  'C+ EWMA .6 censor clip down35':             ewma_clip(0.6, 0.35),
  'C+ EWMA .6 censor clip down25':             ewma_clip(0.6, 0.25),
  'C+ EWMA .7 censor clip down35':             ewma_clip(0.7, 0.35),
  'C+ EWMA .7 censor clip down25':             ewma_clip(0.7, 0.25),
  'C+ EWMA .6 censor clip down35 up50':        ewma_clip(0.6, 0.35, 0.5),
  'E+ Holt .5/.3/.8 censor':                   study.holt(0.5, 0.3, 0.8),
  'E+ Holt .5/.3/.8 censor clip down35':       holt_clip(0.5, 0.3, 0.8, 0.35),
  'E+ Holt .6/.2/.8 censor clip down35':       holt_clip(0.6, 0.2, 0.8, 0.35),
  'X  EWMA .6 censor clip35 + top-up skip':    ewma_topup(0.6, 0.35),
  'G+ rate x elapsed (censor)':                rate_model(0.5, 'elapsed'),
  'Z  rate x typical interval (censor)':       rate_model(0.5, 'typical'),
}

def scenarios(rng):
    irregular = [rng.uniform(24, 72) for _ in range(N)]
    base = study.build_scenarios(random.Random(7))
    extra = [
        scen('S8b irregular intervals, water-when-dry (D const)', [1.2] * N, intervals=irregular, noise=0.10),
        scen('S9b top-up without runoff (20%)', [1.2] * N, events={'topup_dry': 0.2}),
    ]
    return base + extra

# extend the simulator with a dry top-up event (small W, no runoff)
_orig_run = study.run
def run2(cand, sc, seed):
    if 'topup_dry' not in sc['events']:
        return _orig_run(cand, sc, seed)
    rng = random.Random(seed)
    h, scored = [], []
    next_w = None
    for i, d_mean in enumerate(sc['demand']):
        d = d_mean * (1 + rng.uniform(-sc['noise'], sc['noise']))
        w = sc['w0_factor'] * d_mean / (1 - G) if i == 0 else next_w
        w = min(max(w, 0.001), 100)
        r = study.observe(w, d, rng)
        h.append(dict(w=w, r=r, ret=w - r, interval_h=None if i == 0 else 48.0))
        if i >= sc['score_from']: scored.append((i, r / w))
        if rng.random() < sc['events']['topup_dry']:
            # mid-cycle sip: medium half dry (deficit 0.6 L), grower adds 0.3 L, no runoff
            h.append(dict(w=0.3, r=0.0, ret=0.3, interval_h=24.0))
        est = cand(h, 48.0) if getattr(cand, 'needs_elapsed', False) else cand(h)
        next_w = h[-1]['w'] if (est is None or est <= 0) else min(min(est, 10) / (1 - G), 100)
    return scored
study.run = run2

if __name__ == '__main__':
    scs = scenarios(random.Random(11))
    res = {c: {s['name']: metrics(f, s) for s in scs} for c, f in C2.items()}
    json.dump(res, open('results2.json', 'w'), indent=1)
    names = [s['name'] for s in scs]
    short = [n.split()[0] for n in names]
    for key, title in [('mean', 'MEAN ABS RUNOFF ERROR (pp)'), ('zero', 'ZERO-RUNOFF WATERINGS (%)'),
                       ('excess', 'EXCESSIVE RUNOFF > 30% (%)')]:
        print(title)
        print('%-42s' % '' + ''.join('%6s' % s for s in short) + '   avg')
        for c in C2:
            v = [res[c][n][key] for n in names]
            print('%-42s' % c + ''.join('%6.1f' % x for x in v) + '  %5.1f' % (sum(v) / len(v)))
        print()
    print('CONVERGENCE (median waterings to settle within 10-20% runoff): S1b start-low, S6 after drop, S11 after step')
    for c in C2:
        print('%-42s' % c, ' '.join('%5s' % res[c][n]['conv'] for n in names if res[c][n]['conv'] is not None))
