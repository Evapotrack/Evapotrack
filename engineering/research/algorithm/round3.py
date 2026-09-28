import random, statistics as st, json
import study, round2
from study import G, usable, censored, metrics, scen, N

def holt_full(alpha, beta, phi, c_down, topup=False, ratio=0.4):
    def f(h):
        state, intervals = None, []
        for x in h:
            iv = x['interval_h']
            short = topup and iv is not None and len(intervals) >= 2 and iv < ratio * st.median(intervals[-5:])
            if usable(x):
                y = x['ret']
                if state is None:
                    state = (y, 0.0)
                else:
                    l, b = state
                    pred = l + phi * b
                    if not (short and y < 0.6 * pred):
                        y = max(y, pred * (1 - c_down))
                        nl = alpha * y + (1 - alpha) * pred
                        nb = beta * (nl - l) + (1 - beta) * phi * b
                        state = (nl, nb)
            elif censored(x):
                state = (x['w'], 0.0) if state is None else (max(state[0], x['w']), max(state[1], 0.0))
            if iv is not None and not short: intervals.append(iv)
        if state is None: return None
        return max(1e-6, state[0] + phi * state[1])
    return f

C3 = {
  'A  legacy':                              study.cand_legacy,
  'M1 EWMA .6 censor clip25':               round2.ewma_clip(0.6, 0.25),
  'M1T EWMA .6 censor clip25 + top-up':     round2.ewma_topup(0.6, 0.25),
  'H1 Holt .5/.2/.8 censor clip25':         holt_full(0.5, 0.2, 0.8, 0.25),
  'H2 Holt .5/.3/.8 censor clip25':         holt_full(0.5, 0.3, 0.8, 0.25),
  'H3 Holt .6/.2/.8 censor clip25':         holt_full(0.6, 0.2, 0.8, 0.25),
  'H4 Holt .5/.2/.7 censor clip25':         holt_full(0.5, 0.2, 0.7, 0.25),
  'H5 Holt .5/.2/.8 censor clip25 + top-up':holt_full(0.5, 0.2, 0.8, 0.25, topup=True),
  'H6 Holt .5/.2/.8 censor clip35':         holt_full(0.5, 0.2, 0.8, 0.35),
}

def cycle(noise_top=0.0):
    veg = [0.5 * 1.05 ** i for i in range(15)]           # veg growth 5%/watering
    plateau = [veg[-1]] * 10                              # early/mid flower
    late = [veg[-1] * 0.97 ** (i + 1) for i in range(10)] # late flower decline
    return veg + plateau + late

def scenarios():
    base = round2.scenarios(random.Random(11))
    extra = [
        scen('S7b stationary noise +/-30%', [1.2] * N, noise=0.30),
        scen('S12 realistic cycle (veg +5%, plateau, -3%), noise 10%', cycle(), noise=0.10),
        scen('S13 realistic cycle + 10% top-ups + 5% generous', cycle(), noise=0.10,
             events={'topup': 0.10, 'generous': 0.05}),
    ]
    return base + extra

if __name__ == '__main__':
    scs = scenarios()
    res = {c: {s['name']: metrics(f, s) for s in scs} for c, f in C3.items()}
    json.dump(res, open('results3.json', 'w'), indent=1)
    names = [s['name'] for s in scs]
    short = [n.split()[0] for n in names]
    for key, title in [('mean', 'MEAN ABS ERROR (pp)'), ('median', 'MEDIAN ABS ERROR (pp)'),
                       ('zero', 'ZERO RUNOFF (%)'), ('under', 'UNDERSHOOT < 10% (%)'),
                       ('over', 'OVERSHOOT > 20% (%)'), ('excess', 'EXCESSIVE > 30% (%)')]:
        print(title)
        print('%-40s' % '' + ''.join('%6s' % s for s in short) + '   avg')
        for c in C3:
            v = [res[c][n][key] for n in names]
            print('%-40s' % c + ''.join('%6.1f' % x for x in v) + '  %5.1f' % (sum(v) / len(v)))
        print()
    print('CONVERGENCE S1b / S6 / S11 (median waterings)')
    for c in C3:
        print('%-40s' % c, ' '.join('%5s' % res[c][n]['conv'] for n in names if res[c][n]['conv'] is not None))
