import engine_ref as E

def legacy(obs, mrc, goal=15.0):
    """Exact port of PlantDashboardViewModel.averageRetained +
    WateringCalculationService.computeNextWaterRecommendation (89cc8c8)."""
    if not obs: return None
    # WateringLog.init clamps
    logs = [(max(w, 0.001), max(r, 0.0), t) for w, r, t in obs]
    rets = [max(0.0, w - r) for w, r, t in logs]
    newest = max(range(len(logs)), key=lambda i: (logs[i][2], -i))   # sorted newest first; ties keep order
    # VM sorts by dateTime descending (stable sort): first element = newest; for ties, earlier input first
    order = sorted(range(len(logs)), key=lambda i: -logs[i][2])
    last = rets[order[0]]
    avg = sum(rets) / len(rets)
    if last <= 0: return None
    f = 1 - goal / 100
    if f <= 0: return None
    exp = (last + avg) / 2
    nxt = min(exp / f, mrc / f)
    return nxt, nxt * goal / 100

steady = [(1.20, 0.18, i) for i in range(4)]
cases = {
  'oneWatering':            ([(1.20, 0.18, 0)], 4.5, 15),
  'steadyHistory':          ([(1.20, 0.18, i) for i in range(5)], 4.5, 15),
  'multipleWaterings':      ([(1.00, 0.15, 0), (1.20, 0.20, 1), (1.10, 0.10, 2)], 4.5, 15),
  'zeroRunoffLast':         (steady + [(1.20, 0.00, 9)], 4.5, 15),
  'fullRunoffLast':         (steady + [(1.20, 1.20, 9)], 4.5, 15),
  'highRunoffLast':         (steady + [(1.20, 0.48, 9)], 4.5, 15),
  'topUpLast':              (steady + [(0.30, 0.05, 9)], 4.5, 15),
  'largeWateringLast':      (steady + [(3.00, 0.45, 9)], 4.5, 15),
  'risingDemand':           ([(0.40, 0.06, 0), (0.50, 0.07, 1), (0.70, 0.10, 2), (1.00, 0.15, 3), (1.40, 0.20, 4), (1.90, 0.28, 5)], 4.5, 15),
  'decliningDemand':        ([(1.90, 0.30, 0), (1.70, 0.30, 1), (1.50, 0.30, 2), (1.30, 0.30, 3), (1.10, 0.30, 4)], 4.5, 15),
  'goal90':                 (steady, 4.5, 90),
  'goal99_9':               (steady, 4.5, 99.9),
  'mrcCap':                 (steady, 0.9, 15),
  'rising_manyOld':         ([(0.40, 0.06, i) for i in range(30)] + [(2.0, 0.30, 30 + i) for i in range(3)], 4.5, 15),
}
print('--- LEGACY ---')
for name, (obs, mrc, goal) in cases.items():
    print(f'{name:22s}', legacy(obs, mrc, goal))
print('--- ENGINE ---')
engine_cases = dict(cases)
engine_cases.update({
  'dryTopUpLast':           (steady + [(0.30, 0.00, 9)], 4.5, 15),
  'noRunoffOnly':           ([(0.60, 0.00, 0)], 4.5, 15),
  'noRunoffAboveForecast':  (steady + [(1.30, 0.00, 9)], 4.5, 15),
  'allFullRunoff':          ([(1.0, 1.0, 0), (0.8, 0.8, 1)], 4.5, 15),
  'goal2':                  (steady, 4.5, 2),
  'goalNaN':                (steady, 4.5, float('nan')),
  'maxInput':               ([(95.0, 5.0, 0)], 100.0, 50),
  'measuredAfterNoRunoff':  ([(0.60, 0.0, 0), (1.40, 0.20, 1)], 4.5, 15),
})
for name, (obs, mrc, goal) in engine_cases.items():
    r = E.recommend(obs, mrc, goal)
    if isinstance(r, dict):
        print(f'{name:22s} next={r["next"]:.10f} goalRunoff={r["goalRunoff"]:.10f} est={r["estimate"]:.10f} g={r["goal"]} basis={r["basis"]} notes={r["notes"]}')
    else:
        print(f'{name:22s} {r}')
# homogeneity
k = 3.785411784
obs = cases['risingDemand'][0]
a = E.recommend(obs, 4.5, 15)['next']; b = E.recommend([(w * k, r * k, t) for w, r, t in obs], 4.5 * k, 15)['next']
print('homogeneity', a * k, b, abs(a * k - b))
