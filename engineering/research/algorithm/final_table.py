import json, statistics as st, random
import study, round2, round3, engine_ref
from study import metrics
scs = round3.scenarios()
C = {'Current (legacy)': study.cand_legacy, 'Shipped engine': engine_ref.as_candidate()}
res = {c: {s['name']: metrics(f, s) for s in scs} for c, f in C.items()}
json.dump(res, open('final.json', 'w'), indent=1)
print('%-58s %28s   %28s' % ('', 'CURRENT (legacy)', 'SHIPPED ENGINE'))
print('%-58s %7s%7s%7s%7s   %7s%7s%7s%7s' % ('scenario', 'mean', 'med', 'zero%', '>30%', 'mean', 'med', 'zero%', '>30%'))
for s in scs:
    n = s['name']; a = res['Current (legacy)'][n]; b = res['Shipped engine'][n]
    print('%-58s %7.1f%7.1f%7.1f%7.1f   %7.1f%7.1f%7.1f%7.1f' % (n, a['mean'], a['median'], a['zero'], a['excess'], b['mean'], b['median'], b['zero'], b['excess']))
for key in ('mean', 'median', 'zero', 'excess', 'over', 'under'):
    a = st.mean(res['Current (legacy)'][s['name']][key] for s in scs)
    b = st.mean(res['Shipped engine'][s['name']][key] for s in scs)
    print('average %-8s legacy %5.1f   engine %5.1f' % (key, a, b))
for tag in ('S1b', 'S6', 'S11'):
    n = [s['name'] for s in scs if s['name'].startswith(tag)][0]
    print('convergence', tag, 'legacy', res['Current (legacy)'][n]['conv'], 'engine', res['Shipped engine'][n]['conv'])
base = res['Shipped engine'][[s['name'] for s in scs if s['name'].startswith('S1 ')][0]]['mean']
for tag in ('S9 ', 'S10a', 'S10b', 'S13'):
    n = [s['name'] for s in scs if s['name'].startswith(tag)][0]
    lb = res['Current (legacy)'][[s['name'] for s in scs if s['name'].startswith('S1 ')][0]]['mean']
    print('outlier sensitivity', tag, 'legacy +%.1f pp' % (res['Current (legacy)'][n]['mean'] - lb), ' engine +%.1f pp' % (res['Shipped engine'][n]['mean'] - base))
