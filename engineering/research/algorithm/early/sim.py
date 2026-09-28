# Faithful port of WateringCalculationService + PlantDashboardViewModel + validation
def log(w, r):
    w = max(w, 0.001); r = max(r, 0)
    return dict(w=w, r=r, ret=max(0, w - r), rp=min(r / w * 100, 100))

def next_rec(logs_newest_first, mrc, g=15.0):
    if not logs_newest_first: return None
    last = logs_newest_first[0]
    avg = sum(l['ret'] for l in logs_newest_first) / len(logs_newest_first)
    if last['ret'] <= 0: return None
    f = 1 - g / 100
    exp = (last['ret'] + avg) / 2
    n = min(exp / f, mrc / f)
    return n, n * g / 100, exp, avg

def valid(w, r, mrc):
    if not (0.001 <= w <= 100): return 'water range'
    if not (0 <= r <= w): return 'runoff range'
    if w - r > mrc * 1.05: return 'REJECT retained>105%MRC'
    return 'ok'

def row(name, hist, mrc=4.5, g=15.0):
    logs = [log(*x) for x in hist][::-1]   # input oldest-first -> newest-first
    res = next_rec(logs, mrc, g)
    last = hist[-1]
    if res is None:
        print(f"{name:38s} last W={last[0]:.2f} R={last[1]:.2f}  -> NEXT = nil ('No insights yet')")
    else:
        n, gr, exp, avg = res
        cap = ' (CAPPED)' if abs(n - mrc/(1-g/100)) < 1e-9 else ''
        print(f"{name:38s} last W={last[0]:.2f} R={last[1]:.2f} ret={last[0]-last[1]:.3f} avg={avg:.3f} E={exp:.3f} -> Next={n:.3f} L goalRunoff={gr:.3f}{cap}")

print("=== Test matrix (MRC 4.5 L = 3 gal soil per website table, goal 15%) ===")
row("First watering", [(1.20, 0.18)])
row("Normal, steady (5 logs)", [(1.2,0.18)]*5)
row("High runoff last (40%)", [(1.2,0.18)]*4 + [(1.2,0.48)])
row("Zero runoff last (censored)", [(1.2,0.18)]*4 + [(1.2,0.0)])
row("Runoff == water added last", [(1.2,0.18)]*4 + [(1.2,1.2)])
row("Small watering last", [(1.2,0.18)]*4 + [(0.3,0.05)])
row("Unusually large watering last", [(1.2,0.18)]*4 + [(3.0,0.45)])
row("Seedling->veg growth (ret rising)", [(0.4,0.06),(0.5,0.07),(0.7,0.1),(1.0,0.15),(1.4,0.2),(1.9,0.28)])
row("Many old small logs + recent big", [(0.4,0.06)]*30 + [(2.0,0.3)]*3)
row("Low runoff 5% (docs test case)", [(1.0,0.5)]*0 + [(1.0,0.05)], mrc=2.0)
print()
print("=== Validation / MRC interaction ===")
print("MRC from calculator on moist medium = 0.8 L; later drier watering W=1.5 R=0.2:", valid(1.5,0.2,0.8))
print("MRC 1.6 L (in-app example data, '3 gal soil'), website table says 4.5 L")
print()
print("=== Convergence: true deficit D=1.2 L constant, grower starts at 0.6 L & follows Next ===")
D=1.2; hist=[]; W=0.6
for i in range(12):
    r = max(0, W - D); hist.append((W, r))
    n = next_rec([log(*x) for x in hist][::-1], 4.5)[0]
    print(f"  #{i+1:2d} W={W:.3f} runoff={r:.3f} ({(r/W*100):4.1f}%)  next={n:.3f}")
    W = n
print()
print("=== Tracking a rising demand (+8%/watering), grower follows Next ===")
D=0.6; hist=[]; W=0.7
for i in range(15):
    r = max(0, W - D); hist.append((W, r))
    n = next_rec([log(*x) for x in hist][::-1], 10)[0]
    print(f"  #{i+1:2d} D={D:.3f} W={W:.3f} runoff%={(r/W*100):5.1f}  next={n:.3f}")
    W = n; D *= 1.08
print()
print("=== Weight of each log in E (n logs): last = 0.5+0.5/n, others 0.5/n ===")
for n in (1,2,3,5,10,50,200): print(f"  n={n:3d}: w_last={0.5+0.5/n:.3f} w_each_older={0.5/n:.4f}")
