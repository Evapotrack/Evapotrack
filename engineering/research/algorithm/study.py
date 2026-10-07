"""
Closed-loop comparison of Next-watering estimators for EvapoTrack.

Physical model (per watering): the medium has a deficit D (volume it absorbs
before free drainage starts). The grower adds W. Runoff R = max(0, W - D)
(plus a small reading error when runoff exists). Retained = W - R.
  * R > 0  -> retained == D (uncensored measurement of the deficit)
  * R == 0 -> retained == W <= D (censored: only a lower bound on D)
Every candidate predicts D_hat; Next = min(D_hat, MRC) / (1 - g), clamped to 100 L.
The grower follows Next unless a scenario event says otherwise.
"""
import random, statistics as st, math

G = 0.15          # goal runoff fraction
MRC = 10.0        # large, so the cap does not interfere
MAX_W = 100.0

# ---------------------------------------------------------------- candidates
# Each candidate is a function(history) -> D_hat or None.
# history: list of dict(w, r, ret, interval_h) oldest first.

def cand_legacy(h):                       # A: exact port of the current app
    rets = [x['ret'] for x in h]
    last = rets[-1]
    if last <= 0: return None
    return (last + sum(rets) / len(rets)) / 2

def usable(x):   return x['r'] > 0 and x['ret'] > 0     # uncensored, informative
def censored(x): return x['r'] == 0

def smoother(update, init=lambda y: y, censor=True):
    """Builds a candidate from a scalar state update. With censor=True:
    uncensored obs update normally; censored obs raise the level to at least W;
    full-runoff obs (ret == 0) are skipped. With censor=False every obs is used
    as if exact (ret), except ret == 0 which gives None when it is the latest."""
    def f(h):
        state = None
        for x in h:
            if censor:
                if usable(x):
                    y = x['ret']
                    state = init(y) if state is None else update(state, y)
                elif censored(x):
                    state = init(x['w']) if state is None else raise_to(state, x['w'])
                # ret == 0 with runoff -> skipped
            else:
                y = x['ret']
                state = init(y) if state is None else update(state, y)
        if state is None: return None
        if not censor and h[-1]['ret'] <= 0: return None
        return level(state)
    return f

def level(s):      return s[0] if isinstance(s, tuple) else s
def raise_to(s, w):
    if isinstance(s, tuple):
        return (max(s[0], w),) + tuple(s[1:])
    return max(s, w)

def ewma(alpha, censor=True):
    return smoother(lambda s, y: alpha * y + (1 - alpha) * s, censor=censor)

def ewma_clipped(alpha, c):
    def upd(s, y):
        y = min(max(y, s * (1 - c)), s * (1 + c))
        return alpha * y + (1 - alpha) * s
    return smoother(upd)

def holt(alpha, beta, phi, censor=True):
    def init(y): return (y, 0.0)
    def upd(s, y):
        l, b = s
        pred = l + phi * b
        nl = alpha * y + (1 - alpha) * pred
        nb = beta * (nl - l) + (1 - beta) * phi * b
        return (nl, nb)
    base = smoother(upd, init=init, censor=censor)
    def f(h):
        # forecast one step ahead: level + phi * trend
        state = None
        for x in h:
            ok_u = usable(x) if censor else True
            if ok_u:
                y = x['ret']
                state = init(y) if state is None else upd(state, y)
            elif censor and censored(x):
                state = init(x['w']) if state is None else (max(state[0], x['w']), max(state[1], 0.0))
        if state is None: return None
        if not censor and h[-1]['ret'] <= 0: return None
        return max(1e-6, state[0] + phi * state[1])
    return f

def window(n, kind, censor=True):
    """kind='lin' linearly recency-weighted mean of last n; kind='median'."""
    def f(h):
        vals = []
        est = None
        for x in h:
            if censor:
                if usable(x): y = x['ret']
                elif censored(x): y = x['w'] if est is None else max(x['w'], est)
                else: continue
            else:
                y = x['ret']
            vals.append(y)
            last = vals[-n:]
            if kind == 'lin':
                wts = list(range(1, len(last) + 1))
                est = sum(v * w for v, w in zip(last, wts)) / sum(wts)
            else:
                est = st.median(last)
        if est is None: return None
        if not censor and h[-1]['ret'] <= 0: return None
        return est
    return f

def latest(censor=True):
    return ewma(1.0, censor=censor)

def legacy_censor(h):                     # A + censor layer (for reference)
    rets = [x['ret'] for x in h if usable(x)]
    bound = 0.0
    for x in reversed(h):
        if usable(x): break
        if censored(x): bound = max(bound, x['w'])
    if not rets: return bound or None
    last = rets[-1]
    return max((last + sum(rets) / len(rets)) / 2, bound)

def feedback(k):                          # F: runoff-feedback on the water amount
    def f(h):
        x = h[-1]
        r = x['r'] / x['w']
        w_next = x['w'] * ((1 - r) / (1 - G)) ** k
        return w_next * (1 - G)           # expressed as D_hat so Next = w_next
    return f

def rate_based(alpha):                    # G (info only): retained per hour x elapsed
    def f(h, elapsed_h=None):
        rate = None
        for x in h:
            if x['interval_h'] is None or not usable(x): continue
            y = x['ret'] / x['interval_h']
            rate = y if rate is None else alpha * y + (1 - alpha) * rate
        if rate is None or elapsed_h is None:
            return ewma(0.5)(h)
        return rate * elapsed_h
    f.needs_elapsed = True
    return f

CANDIDATES = {
    'A  legacy 0.5*last + 0.5*all-time mean': cand_legacy,
    'A+ legacy + censor layer':               legacy_censor,
    'B  latest only (naive)':                 latest(censor=False),
    'B+ latest only + censor':                latest(),
    'C  EWMA a=0.3 (naive)':                  ewma(0.3, censor=False),
    'C  EWMA a=0.5 (naive)':                  ewma(0.5, censor=False),
    'C  EWMA a=0.7 (naive)':                  ewma(0.7, censor=False),
    'C+ EWMA a=0.3 + censor':                 ewma(0.3),
    'C+ EWMA a=0.5 + censor':                 ewma(0.5),
    'C+ EWMA a=0.7 + censor':                 ewma(0.7),
    'C+ EWMA a=0.5 + censor + clip 50%':      ewma_clipped(0.5, 0.5),
    'C+ EWMA a=0.7 + censor + clip 50%':      ewma_clipped(0.7, 0.5),
    'D+ recency-weighted N=3 + censor':       window(3, 'lin'),
    'D+ recency-weighted N=4 + censor':       window(4, 'lin'),
    'D+ recency-weighted N=5 + censor':       window(5, 'lin'),
    'D+ recency-weighted N=7 + censor':       window(7, 'lin'),
    'D+ median of last 3 + censor':           window(3, 'median'),
    'D+ median of last 5 + censor':           window(5, 'median'),
    'E+ Holt a=0.5 b=0.3 phi=0.8 + censor':   holt(0.5, 0.3, 0.8),
    'E+ Holt a=0.5 b=0.3 phi=1.0 + censor':   holt(0.5, 0.3, 1.0),
    'E+ Holt a=0.7 b=0.2 phi=0.9 + censor':   holt(0.7, 0.2, 0.9),
    'F  runoff feedback k=0.5':               feedback(0.5),
    'F  runoff feedback k=1.0':               feedback(1.0),
    'G  rate x elapsed (info only)':          rate_based(0.5),
}

# ----------------------------------------------------------------- scenarios
N = 30
def base_intervals(n, hours=48.0): return [hours] * n

def scen(name, demand, intervals=None, noise=0.05, w0_factor=0.8, events=None, score_from=3):
    return dict(name=name, demand=demand, intervals=intervals or base_intervals(len(demand)),
                noise=noise, w0_factor=w0_factor, events=events or {}, score_from=score_from)

def growth(d0, pct, n=N, cap=3.0): return [min(cap, d0 * (1 + pct) ** i) for i in range(n)]
def decline(d0, pct, n=N, floor=0.4): return [max(floor, d0 * (1 - pct) ** i) for i in range(n)]

def build_scenarios(rng):
    irregular = [rng.uniform(24, 72) for _ in range(N)]
    s = [
        scen('S1  constant 1.2 L (+/-5%)', [1.2] * N),
        scen('S1b constant, first watering 50% low', [1.2] * N, w0_factor=0.5, score_from=0),
        scen('S2  growth +3%/watering', growth(0.6, 0.03)),
        scen('S3  growth +6%/watering', growth(0.6, 0.06)),
        scen('S4  growth +10%/watering', growth(0.4, 0.10)),
        scen('S5  decline -5%/watering', decline(1.5, 0.05)),
        scen('S6  sudden 35% drop at #15', [1.2] * 15 + [0.78] * 15, score_from=0),
        scen('S7  stationary noise +/-20%', [1.2] * N, noise=0.20),
        scen('S8  irregular intervals 1-3 days', [0.6 * h / 24 for h in irregular], intervals=irregular),
        scen('S9  occasional top-up (20%)', [1.2] * N, events={'topup': 0.2}),
        scen('S10a occasional 2x generous watering', [1.2] * N, events={'generous': 0.1}),
        scen('S10b occasional long gap (D x1.8)', [1.2] * N, events={'gap': 0.1}),
        scen('S11 20x 0.6 L, then step to 1.2 L', [0.6] * 20 + [1.2] * 10, score_from=0),
    ]
    return s

# ------------------------------------------------------------------ simulate
def observe(w, d, rng):
    r = max(0.0, w - d)
    if r > 0:
        r = max(0.0005, r + rng.uniform(-0.01, 0.01))   # reading error, still visible
        r = min(r, w)
    return r

def run(cand, sc, seed):
    rng = random.Random(seed)
    h, scored, labels = [], [], []
    needs_elapsed = getattr(cand, 'needs_elapsed', False)
    next_w = None
    for i, d_mean in enumerate(sc['demand']):
        interval = sc['intervals'][i]
        d = d_mean * (1 + rng.uniform(-sc['noise'], sc['noise']))
        ev = sc['events']
        gap = 'gap' in ev and i > 2 and rng.random() < ev['gap']
        if gap: d *= 1.8
        if i == 0:
            w = sc['w0_factor'] * d_mean / (1 - G)
        else:
            w = next_w
        generous = 'generous' in ev and i > 2 and rng.random() < ev['generous']
        if generous: w *= 2
        w = min(max(w, 0.001), MAX_W)
        r = observe(w, d, rng)
        h.append(dict(w=w, r=r, ret=w - r, interval_h=None if i == 0 else interval))
        if i >= sc['score_from'] and not generous:
            scored.append((i, r / w))
        # optional top-up six hours later (not scored, but recorded)
        if 'topup' in ev and rng.random() < ev['topup']:
            d_top = d_mean * 0.12
            wt = 0.30
            rt = observe(wt, d_top, rng)
            h.append(dict(w=wt, r=rt, ret=wt - rt, interval_h=6.0))
        elapsed = sc['intervals'][i + 1] if i + 1 < len(sc['intervals']) else interval
        est = cand(h, elapsed) if needs_elapsed else cand(h)
        if est is None or not math.isfinite(est) or est <= 0:
            next_w = h[-1]['w']            # app shows nothing; grower repeats
        else:
            next_w = min(min(est, MRC) / (1 - G), MAX_W)
    return scored

def convergence(scored, start_idx):
    """First watering index >= start_idx after which runoff stays within
    [10%, 20%] for 3 consecutive waterings; returns waterings needed."""
    seq = [(i, rp) for i, rp in scored if i >= start_idx]
    for k in range(len(seq) - 2):
        if all(0.10 <= seq[k + j][1] <= 0.20 for j in range(3)):
            return seq[k][0] - start_idx
    return 30

def metrics(cand, sc, seeds=200):
    all_rp, conv = [], []
    for seed in range(seeds):
        scored = run(cand, sc, seed)
        all_rp += [rp for _, rp in scored]
        if sc['name'].startswith('S1b'): conv.append(convergence(scored, 0))
        if sc['name'].startswith('S6'):  conv.append(convergence(scored, 15))
        if sc['name'].startswith('S11'): conv.append(convergence(scored, 20))
    err = [abs(rp - G) * 100 for rp in all_rp]
    n = len(all_rp)
    return dict(
        mean=st.mean(err), median=st.median(err),
        zero=100 * sum(rp < 0.001 for rp in all_rp) / n,
        excess=100 * sum(rp > 2 * G for rp in all_rp) / n,
        over=100 * sum(rp > G + 0.05 for rp in all_rp) / n,
        under=100 * sum(rp < G - 0.05 for rp in all_rp) / n,
        conv=st.median(conv) if conv else None,
    )

if __name__ == '__main__':
    import json, sys
    scenarios = build_scenarios(random.Random(7))
    results = {}
    for cname, cand in CANDIDATES.items():
        results[cname] = {sc['name']: metrics(cand, sc) for sc in scenarios}
    json.dump(results, open('results.json', 'w'), indent=1)
    print('done', len(results), 'candidates x', len(scenarios), 'scenarios')
