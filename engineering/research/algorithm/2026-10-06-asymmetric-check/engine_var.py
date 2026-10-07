"""
Variant of engine_ref.py (revision 2) with one extra parameter, a_up: the
smoothing weight used when a watering retained MORE than the forecast.
a_up = ALPHA (0.5) reproduces engine_ref.py exactly.
"""
import math

ALPHA, BETA, PHI = 0.5, 0.2, 0.8
MAX_DROP = 0.25          # one watering can lower the forecast by at most 25%
TREND_CAP = 0.25         # trend contributes at most +/-25% of the level
NOTABLE_TREND = 0.05     # explanation mentions a trend at >= 5% of the level
GOAL_MIN, GOAL_MAX, GOAL_DEFAULT = 5.0, 50.0, 15.0
MAX_WATER = 100.0

def kind(w, r):
    if not (math.isfinite(w) and math.isfinite(r)) or w <= 0 or r < 0: return 'invalid'
    if r >= w: return 'full'
    if r == 0: return 'noRunoff'
    return 'measured'

def forecast(level, trend):
    t = max(-TREND_CAP * level, min(TREND_CAP * level, PHI * trend))
    return level + t

def recommend(obs, mrc, goal, a_up=ALPHA):
    """obs: list of (w, r, t) in any order; returns dict or outcome string."""
    if not obs: return 'noHistory'
    ordered = sorted(enumerate(obs), key=lambda p: (p[1][2], p[0]))
    level, trend, has_measure, measured = None, 0.0, False, 0
    last_kind, last_w, last_raised = None, None, False
    for _, (w, r, t) in ordered:
        k = kind(w, r)
        raised = False
        if k == 'measured':
            y = w - r
            measured += 1
            if level is None or not has_measure:
                level, trend = y, 0.0
            else:
                f = forecast(level, trend)
                y_eff = max(y, f * (1 - MAX_DROP))
                a = a_up if y_eff > f else ALPHA
                new_level = a * y_eff + (1 - a) * f
                trend = BETA * (new_level - level) + (1 - BETA) * PHI * trend
                level = new_level
            has_measure = True
        elif k == 'noRunoff':
            if level is None:
                level, trend, raised = w, 0.0, True
            elif w > forecast(level, trend):
                level, trend, raised = w, max(trend, 0.0), True
        last_kind, last_w, last_raised = k, w, raised
    if level is None: return 'noUsableData'
    notes = []
    estimate = forecast(level, trend)
    trend_part = estimate - level
    if trend_part >= NOTABLE_TREND * level: notes.append('demandRising')
    elif trend_part <= -NOTABLE_TREND * level: notes.append('demandFalling')
    if last_kind == 'noRunoff': notes.insert(0, ('lastWateringNoRunoff', last_w, last_raised))
    if last_kind == 'full': notes.insert(0, 'lastWateringFullRunoff')
    if math.isfinite(mrc) and mrc > 0 and estimate > mrc:
        estimate = mrc; notes.append(('limitedByCapacity', mrc))
    g = goal
    if not math.isfinite(g): g = GOAL_DEFAULT; notes.append(('goalAdjusted', goal))
    elif g < GOAL_MIN or g > GOAL_MAX:
        notes.append(('goalAdjusted', goal)); g = min(max(g, GOAL_MIN), GOAL_MAX)
    nxt = estimate / (1 - g / 100)
    if nxt > MAX_WATER:
        nxt = MAX_WATER; notes.append(('limitedByMaximumInput', MAX_WATER))
    basis = ('measured', measured) if has_measure else ('noRunoffLowerBound',)
    return dict(next=nxt, goalRunoff=nxt * g / 100, goal=g, estimate=estimate, basis=basis, notes=notes)

# ---- closed-loop adapter so the final engine runs through the same study harness
def as_candidate(a_up=ALPHA):
    def f(h):
        res = recommend([(x["w"], x["r"], i) for i, x in enumerate(h)], 1e9, 15.0, a_up)
        return res['estimate'] if isinstance(res, dict) else None
    return f
