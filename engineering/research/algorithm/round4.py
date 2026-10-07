import random, statistics as st, json
import study, round2, round3
from study import usable, censored, metrics

def holt_cap(alpha, beta, phi, c_down, cap):
    """Holt level+trend; censored obs raise the level (trend floored at 0);
    one observation can pull the level down by at most c_down of the forecast;
    the trend's contribution to the forecast is limited to +/- cap x level."""
    def f(h):
        state = None
        for x in h:
            if usable(x):
                y = x['ret']
                if state is None:
                    state = (y, 0.0); continue
                l, b = state
                pred = l + phi * b
                y = max(y, pred * (1 - c_down))
                nl = alpha * y + (1 - alpha) * pred
                nb = beta * (nl - l) + (1 - beta) * phi * b
                state = (nl, nb)
            elif censored(x):
                state = (x['w'], 0.0) if state is None else (max(state[0], x['w']), max(state[1], 0.0))
        if state is None: return None
        l, b = state
        t = max(-cap * l, min(cap * l, phi * b))
        return max(1e-6, l + t)
    return f

scs = round3.scenarios()
keep = ['S1', 'S1b', 'S3', 'S4', 'S5', 'S6', 'S7b', 'S8b', 'S9', 'S12', 'S13']
scs = [s for s in scs if s['name'].split()[0] in keep]
C4 = {'M1 EWMA .6/clip25': round2.ewma_clip(0.6, 0.25), 'H1 Holt .5/.2/.8/clip25': round3.holt_full(0.5, 0.2, 0.8, 0.25)}
for b in (0.1, 0.2, 0.3):
    for p in (0.7, 0.8, 0.9):
        C4[f'Hcap a.5 b{b} phi{p} cap25'] = holt_cap(0.5, b, p, 0.25, 0.25)
res = {c: {s['name']: metrics(f, s) for s in scs} for c, f in C4.items()}
names = [s['name'] for s in scs]
print('%-30s' % 'model (zero% / mean err pp)' + ''.join('%11s' % n.split()[0] for n in names) + '    avg')
for c in C4:
    z = [res[c][n]['zero'] for n in names]; m = [res[c][n]['mean'] for n in names]
    print('%-30s' % c + ''.join('%5.1f/%4.1f ' % (a, e) for a, e in zip(z, m)) + ' %4.1f/%4.1f' % (st.mean(z), st.mean(m)))
print()
print('S6 convergence after drop:', {c: res[c][[n for n in names if n.startswith("S6")][0]]['conv'] for c in C4})
