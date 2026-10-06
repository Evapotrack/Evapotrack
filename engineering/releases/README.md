# EvapoTrack release history

This file is the permanent record of every build that reached the App Store, plus work that is waiting to ship.
Each entry says which source commit the build came from, how sure we are, and where to find the code.

**How to see the exact code of a past release.** No source is copied into this folder, because a second copy of the app would drift and could confuse Xcode. Git already keeps every past version, so each release is pinned by a tag instead:

```sh
git checkout v1.1           # browse or build the v1.1 source (detached HEAD)
git archive -o evapotrack-v1.1-source.zip v1.1   # a zip of exactly that source
git diff v1.0 v1.1 -- Evapotrack                 # everything that changed in the app
```

> Status: the `v1.0` and `v1.1` tags are **proposed, not yet created**. Confirm the commits below against Xcode Organizer and App Store Connect first; see "Confirming a release's commit".

Each release folder (`v1.1/`, …) holds evidence and screenshots for that release only.

---

## v1.1 (build 1): live on the App Store

| | |
|---|---|
| Version shown in the app | `Evapotrack v1.1 (1)` (Settings footer, seen on device 2026-10-06) |
| Source commit (best evidence) | `c063360` (2026-04-01), "v1.1: Dynamic Type polish for accessibility text sizes", the last commit before 2026-10 that changed app code |
| Proposed tag | `v1.1` → `c063360` |
| Version in the repository | **Still 1.0 (1).** The bump to 1.1 was made in Xcode for the archive and never committed (see the plan, step R1) |
| Released | **Unknown: check App Store Connect** → Evapotrack → App Store → version history |
| Evidence | [`v1.1/device-screenshots/`](v1.1/device-screenshots/) from an iPhone after an automatic update |

**What changed from v1.0 (app code only):**
- `761ff6e` (2026-03-29): How To › Watering Protocol now links to evapotrack.com/watering-protocol.
- `c063360` (2026-04-01): Dynamic Type polish in 12 views, for the **accessibility** text sizes:
  - The Summary and Insights grids drop to 1 column.
  - The Plant Info row stacks vertically.
  - Collapsed watering-log rows stack vertically.
  - Plant names can use up to 3 lines.
  - Icons and chart dots scale (`@ScaledMetric`), and the chart height scales up to 400 pt.
  - The language picker can grow.

**Evidence the device build is this commit and not a later branch:**
- The settings footer reads v1.1 (1). No branch ever committed 1.1, so the version was set at archive time.
- Insights match the original algorithm: Next = ((0.90 + 0.91) / 2) ÷ 0.85 = **1.06 L**, as shown. Revision 2's engine would show "Expected" and explanation lines.
- Example data uses Max Capacity **1.60 L** (revision 2 changed it to 1.5 L).
- There is no Edit Plant button, no photo section and no Settings Storage row, all of which the unmerged branches add.

## v1.0 (build 1): first App Store release

| | |
|---|---|
| Version shown in the app | `Evapotrack v1.0 (1)` (see `screenshots/dark-mode/02-settings-global.png`) |
| Source commit (best evidence) | `fed761b` or `23611ba` (both 2026-03-25). `23611ba` added the iPad orientations "for App Store upload", and `fed761b` (4 hours later) added in-app reference-table mentions. Which one was archived is **not yet confirmed** |
| Proposed tag | `v1.0` → whichever commit matches the Organizer archive time |
| Live by | 2026-03-29 (`7ead1f8` added the App Store link to the website) |
| Evidence | `screenshots/dark-mode/` and `screenshots/light-mode/` (simulator captures from 2026-03-15 and 2026-03-21; they predate the second example plant added on 2026-03-22) |

## Pre-release history (2026-03-01 → 2026-03-25)

- `87f5ee3` and `d9c689b` (2026-03-01): the initial commit and the complete first app.
- 2026-03-05 → 03-15: export, limits, the chart, overlays, EN/ES language, iPad layout, accessibility and How To content.
- 2026-03-21: copyright notices, the dark-mode screenshot set, and the first website.
- 2026-03-22: the second example plant (coco, 5 gal), 100% runoff allowed, and iPad improvements.

## Unreleased work (not built, not tested, not merged)

| Branch | Date | Content | Status |
|---|---|---|---|
| `claude/wonderful-edison-i0ukly` | 2026-09-27 → 30 | "Revision 2": new recommendation engine, versioned schema and migration, locale-aware number input, Edit Plant, accessibility, optional photos through **PhotosPicker** (no permissions), website corrections, and 268 tests | Never compiled; see its `engineering/revision-2/IMPLEMENTATION-REPORT.md` |
| `claude/matts-hydroponics-outreach-vwiicq` | 2026-07-26 | Photos through the **camera** (`NSCameraUsageDescription`, photo bytes stored in SwiftData without a versioned schema), plus `ReleasePlan.md` and `ProjectStatus.md` | Never compiled; **conflicts with revision 2** (see the plan, decision D1) |

---

## Confirming a release's commit

1. On the Mac: Xcode › Window › Organizer › Archives › Evapotrack. Note the date and time of each archive that was uploaded (v1.0 and v1.1).
2. Pick the last commit before each archive time: `git log --until="<archive time>" -1 --format='%h %ad %s' main`.
3. If the Mac had uncommitted changes at archive time (for example the version bump), the tag still points at the closest commit. Record the difference in this file.
4. Create annotated tags, then push them:

```sh
git tag -a v1.0 <commit> -m "Evapotrack 1.0 (1), first App Store release"
git tag -a v1.1 c063360 -m "Evapotrack 1.1 (1); MARKETING_VERSION bumped in Xcode at archive time"
git push origin v1.0 v1.1
```

From then on: commit the version bump **before** archiving, tag the exact commit you archive, and add an entry here.
