"""
2026-10-06 check of revision 2's recommendation engine against the same
closed-loop simulation used to choose it (engineering/research/algorithm/).

Needs study.py, round2.py, round3.py and engine_ref.py from the parent folder,
which arrive with revision 2 (branch claude/wonderful-edison-i0ukly).
Run: python3 check.py   (about 30 seconds)
"""
import os, sys, statistics as st
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE)); sys.path.insert(0, HERE)
import round3, study, engine_var
from study import metrics

scs = round3.scenarios(); names = [s['name'] for s in scs]
print('model            zero%  under%  >2xgoal%  over%  meanErr | conv S1b/S6/S11 | S7 >2x  S8 zero  S8 >2x  S12 zero')
for name, f in [('legacy v1.1', study.cand_legacy), ('rev2 (a=.5)', engine_var.as_candidate()),
                ('a_up=.6', engine_var.as_candidate(0.6)), ('a_up=.7', engine_var.as_candidate(0.7)),
                ('a_up=.8', engine_var.as_candidate(0.8))]:
    r = {s['name']: metrics(f, s) for s in scs}
    avg = lambda k: st.mean(r[n][k] for n in names)
    g = lambda p, k: [r[n][k] for n in names if n.split()[0] == p][0]
    print(f"{name:15s} {avg('zero'):5.1f}  {avg('under'):5.1f}   {avg('excess'):5.1f}   {avg('over'):5.1f}   {avg('mean'):5.2f}  |"
          f" {g('S1b','conv'):4} {g('S6','conv'):4} {g('S11','conv'):4} | {g('S7','excess'):5.1f}  {g('S8','zero'):5.1f}   {g('S8','excess'):5.1f}   {g('S12','zero'):5.1f}")

# The Example Plant exactly as shown on the iPhone (v1.1, 2026-10-06): (water added, retained)
soil = [(1.50, 1.31), (1.25, 0.93), (1.25, 0.93), (1.00, 0.68), (0.89, 0.70), (1.00, 0.90)]
ret = [r for _, r in soil]
legacy = ((ret[-1] + st.mean(ret)) / 2) / 0.85
print(f"\nExample Plant, legacy v1.1: Next {legacy:.2f} L")
for a in (0.5, 0.6, 0.7, 0.8):
    res = engine_var.recommend([(w, w - r, i) for i, (w, r) in enumerate(soil)], 1.6, 15.0, a)
    print(f"Example Plant, a_up={a}: Next {res['next']:.2f} L (expected retained {res['estimate']:.2f} L)")
