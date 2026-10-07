# EvapoTrack Engineering Review

*Periodic engineering review · audit only, no code changed*

Reviewed 27 Sep 2026 · Repo `evapotrack/evapotrack` @ `89cc8c8` · iOS app (`Evapotrack/`) + website (`docs/`)

Labels used throughout: **[FACT]** is shown directly by source or configuration. **[FINDING]** is an issue, inconsistency or risk. **[RECOMMENDATION]** is a proposed change. Severity: [P0] critical, [P1] high, [P2] medium, [P3] low. [verify] marks findings that need a device or Xcode run to confirm.

## Executive summary

**[FACT]** EvapoTrack is a small, tidy SwiftUI + SwiftData app (about 5,400 lines of Swift, 6 XCTest files, no third-party dependencies, no network code, no entitlements) targeting iOS 17. The website is six static HTML pages served by GitHub Pages from `docs/`. The product description in the brief is accurate: it logs water added and runoff, stores retained volume and runoff %, compares retained against a user-entered Max Retention Capacity (MRC), and recommends a next watering amount from history. Temperature and humidity are recorded and charted but not used in any calculation.

- **0** confirmed P0 issues
- **10** P1 findings (2 need device verification)
- **21** P2 findings
- **16** P3 findings

What matters most, in order:

1. **The Next recommendation lags behind a growing plant.** `Next = ((lastRetained + allTimeAverageRetained) / 2) / (1 − goal)`. Half the estimate always comes from the all-time average, so early small waterings keep pulling Next down for the life of the plant. In a simulation where demand rises 6% per watering, a grower who follows Next exactly gets *zero runoff on about 79% of waterings*. That violates the app's own protocol ("you must always have runoff"). Zero-runoff logs then understate demand, which feeds the lag. The in-app help also says "the more logs you record, the more accurate the recommendation becomes", which is false for a growing plant.
2. **Max Retention Capacity means three different things.** The website table gives container capacity from dry (3 gal soil = 4.5 L). The in-app calculator gives what one test watering retained, which depends on how dry the pot was. The built-in example data and the public screenshot use 3 gal soil = 1.6 L. Combined with a hard rule that rejects any log retaining more than 105% of MRC, and plants that cannot be edited, an underestimated MRC blocks valid logs. The only fix available to the user is to delete the plant and its whole history.
3. **Decimal input fails in comma-decimal regions.** Every numeric field is parsed with `Double(text)`, which only accepts `.`. On an iPhone set to Spain, Argentina, Colombia, Germany and similar regions, the decimal pad types `,`, so "1,5" is rejected as "must be a number". This hits the Spanish-speaking audience the app is localized for.
4. **A last watering with 100% runoff hides all insights.** Runoff equal to water added is allowed (a deliberate March 22 change), but it makes retained 0, the recommendation returns `nil`, and the dashboard says "No insights yet" even with dozens of logs.
5. **Data integrity basics are good but not ready for schema change.** Canonical units (liters, °C) are stored unrounded, derived values cannot go stale because logs are immutable, and cascade deletes are correct and tested. However, there is no `VersionedSchema` or migration test, save failures are not rolled back, and there is no restore path except an iOS device backup. Versioning should be added before the photo field.
6. **The website claims Android support** (feature card, About paragraph, privacy policy "Room database", support page "Android 8.0 or later"). There is no Android code in this repository.

**Photo attachments are feasible and fit the architecture cleanly** with no new permissions. Use SwiftUI `PhotosPicker` (out-of-process, no Photos permission prompt, no Info.plist key). Import through a file-backed `Transferable`. Downsample with ImageIO to 2048 px on the long edge and re-encode as HEIC without metadata, which strips GPS. Store the image as a file in Application Support and keep only an optional photo ID on `WateringLog`. Tapping an attached photo opens it in a larger, closable viewer with zoom, so the grower can inspect the plant up close. Budget about 0.45 MB per photo including a thumbnail, so 1,000 photos is about 450 MB. Details are in the Photo attachment feasibility section.

## Inventory & method

| Area | Contents |
| --- | --- |
| iOS app | `Evapotrack/`: App (2), Models (4), Services (9), ViewModels (5), Views (18), Utilities (7), Resources (asset catalog with 8 color sets, app and launch icons, `PrivacyInfo.xcprivacy`) |
| Project | `EvapotrackDev.xcodeproj` (Xcode 26.2, objectVersion 77, file-system-synchronized groups), one shared scheme, targets `EvapotrackDev` (app) and `EvapotrackDevTests` |
| Tests | `EvapotrackDevTests/`: InsightsAlgorithm (20), WateringCalculation (17), UnitConversion (30), Validation (64), Model (13), Navigation/Settings (8): 152 tests. No UI tests. |
| Website | `docs/` (GitHub Pages, `CNAME` evapotrack.com): index, reference, watering-protocol, privacy-policy, support, flyer; 5 screenshots; 29 MB `walkthrough.mp4`; Google verification file |
| Internal docs | `docs/Specification.md`, `DataModel.md`, `Architecture.md`, `Requirements.md`, `NavigationMap.md`, `video-watering-protocol-plan.md`. These sit inside the public Pages root. |
| Ignored / absent | `screenshots/` (working captures, gitignored), `private/`, App Store screenshots. No Android project anywhere in the repo. |

**Method.** I read every Swift file, every test, the project file, the privacy manifest, the color assets and every website page. I checked the formulas against the public dashboard screenshot and they match to the displayed precision: last log 1.00 L / 0.10 L gives Retained 0.24 gal, Capacity 56.2%, Average 0.24 gal, Next 0.28 gal. I ported the calculation code to a script to run the test matrix and compare alternatives. **Limits:** this Linux container has no Swift toolchain or Xcode, so I could not build, run tests, see compiler warnings or test on a device. Items that depend on runtime behavior are marked [verify] .

## Architecture

```
EvapotrackApp  (@main · WindowGroup · .modelContainer([Grow, Plant, WateringLog]) · 3 s LaunchView)
 │   injects SettingsViewModel via .environment; applies color scheme, tint, rounded font
 ├── Presentation (SwiftUI, iOS 17)
 │    ├── GrowListView ─── owns the only NavigationStack, @Query grows, example-data loader
 │    │    └── PlantListView(grow) ── plants from grow.plants (no @Query)
 │    │         └── PlantDashboardView(plant)
 │    │              ├── Plant Info · SummaryPanelView · InsightsPanelView · HistoryPanelView
 │    │              └── HistoryView (list ⇄ Swift Charts; expand/select/delete)
 │    │                   └── WateringLogRowView (inline expand = the only "detail" view)
 │    ├── Sheets (adaptiveSheet: sheet on iPhone, fullScreenCover on iPad)
 │    │    CreateGrowView · CreatePlantView (+ MRC calculator) · AddWateringLogView · SettingsView
 │    ├── HowToView(context: general | addWatering | chart)   static help, 1 external Link
 │    └── Components: DeleteConfirmationView · LimitExceededView · LaunchView
 ├── ViewModels (@Observable @MainActor, configure(modelContext:) pattern)
 │    CreateGrowVM · CreatePlantVM · AddWateringLogVM · PlantDashboardVM · SettingsVM
 ├── Services
 │    ├── CRUD (@MainActor classes): GrowService · PlantService · WateringLogService
 │    └── Pure (enums): WateringCalculationService · UnitConversionService · ValidationService
 │                      DataExportService (+ GrowExportDocument) · HapticService
 ├── Models
 │    ├── SwiftData @Model: Grow ─cascade→ Plant ─cascade→ WateringLog
 │    └── UserSettings (Codable JSON in UserDefaults key "userSettings")
 ├── Utilities: Strings (EN/ES enum) · DisplayFormatter · Validators · Extensions
 │              DateProvider · Logger (OSLog) · Color+Evapotrack
 └── Resources: Assets.xcassets (8 light/dark color sets) · PrivacyInfo.xcprivacy

Website (docs/, GitHub Pages): static HTML with inline CSS; no analytics; no JS except the
flyer's QR generator; YouTube iframe on watering-protocol.html; self-hosted mp4 on index.html.
```

**[FACT]** Build settings for the app target: `SWIFT_VERSION = 5.0`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `IPHONEOS_DEPLOYMENT_TARGET = 17.0`, `TARGETED_DEVICE_FAMILY = 1,2`, iPhone portrait only, iPad all four orientations, generated Info.plist, `ITSAppUsesNonExemptEncryption = NO`, bundle id `com.evapotrack.app`, `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 1`, no Swift packages, no entitlements file, no permission usage strings. The test target does not set MainActor default isolation, so tests use `@MainActor` where they need it.

**[FACT]** Everything runs on the main actor. There is no async work apart from the launch and dismiss timers. That suits the current data scale. It matters for photos, because with MainActor as the default isolation any new image-processing type will run on the main thread unless it is explicitly marked `nonisolated`.

## Data model

**[FACT]** Persistence is SwiftData with the default store configuration: a single on-disk store in Application Support, autosave on, no CloudKit, no `VersionedSchema`, no `SchemaMigrationPlan`. Settings live in UserDefaults as JSON, with a custom decoder that handles missing and legacy keys and is tested.

| Entity / field | Type | Req. | Default | Stored or calculated | Notes |
| --- | --- | --- | --- | --- | --- |
| **Grow**: create and delete only; sorted by `createdAt` descending (`@Query`) |  |  |  |  |  |
| id | UUID | yes | UUID() | stored | `@Attribute(.unique)`. Note that unique attributes upsert: inserting a duplicate id overwrites the existing row, which matters for any future import. |
| growName | String | yes | – | stored | 1–50 characters, unique case-insensitively (checked in the view model only) |
| createdAt | Date | yes | Date() | stored |  |
| plants | [Plant] | yes | [] | relationship | `deleteRule: .cascade`, inverse `Plant.grow` |
| **Plant**: create and delete only; sorted by `createdAt` descending (in memory) |  |  |  |  |  |
| id, plantName | UUID, String | yes |  | stored | name unique within its grow |
| potSize, mediumType | String | yes | – | stored | free text, not used in any calculation |
| maxRetentionCapacity | Double (L) | yes | – | stored | init clamps to ≥ 0.001; validated 0.001–100 L; **cannot be edited** |
| goalRunoffPercent | Double | yes | 15.0 (inline default) | stored | init clamps to 0.1–99.9 |
| createdAt | Date | yes | Date() (inline default) | stored |  |
| wateringLogs | [WateringLog] | yes | [] | relationship | cascade, inverse `WateringLog.plant` |
| grow | Grow? | no | nil | relationship | always set by the UI |
| **WateringLog**: create and delete only (only `intervalHours` is ever changed); sorted by `dateTime` descending |  |  |  |  |  |
| id | UUID | yes | UUID() | stored | unique |
| waterAdded | Double (L) | yes | – | stored | init clamps to ≥ 0.001; validated 0.001–100 L |
| runoffCollected | Double (L) | yes | – | stored | init clamps to ≥ 0; validated 0 ≤ R ≤ W. The comment at `WateringLog.swift:28` still says "< waterAdded". |
| dateTime | Date | yes | – | stored | not in the future; unique per plant to the minute |
| temperatureCelsius | Double? | no | nil | stored | −50…60 °C; display only |
| humidityPercent | Double? | no | nil | stored | 0…100; display only |
| retained | Double (L) | yes | – | **stored, calculated at init** | `max(0, W − R)` |
| runoffPercent | Double | yes | – | **stored, calculated at init** | `min(100, R / W × 100)` |
| intervalHours | Double? | no | nil | **stored, recalculated** | recomputed for every log of the plant on add and delete |
| plant | Plant? | no | nil | relationship |  |
| **Not stored, recomputed on every render:** Capacity % (per log, against the plant's current MRC), average retained, Next and goal runoff (`PlantDashboardViewModel`). |  |  |  |  |  |

**[FINDING]** **Stale-data risk is low today.** `retained` and `runoffPercent` are stored copies of values derived from W and R, but nothing can change W, R or MRC after creation, so they cannot drift. The risk arrives the day log editing is added. Any edit path has to recompute these fields, or they should become computed properties in a schema version bump. `intervalHours` is recomputed for all of a plant's logs on every add and delete, so it is always consistent with the current set of logs.

## Watering formulas (as implemented)

**[FACT]** All quantities are liters unless stated. *W* = water added, *R* = runoff collected, *g* = plant goal runoff % (default 15), *MRC* = plant Max Retention Capacity. Logs are indexed *i = 1…n*, newest first.

```
// WateringLog.init  (WateringLog.swift:69-84), stored at creation
W'          = max(W, 0.001)
R'          = max(R, 0)
retained_i  = max(0, W' − R')
runoff%_i   = min(100, R' / W' × 100)

// WateringCalculationService.capacityPercent  (:49-53), computed per render
capacity%_i = MRC > 0 ? min(105, retained_i / MRC × 100) : 0

// recalculateIntervalHours  (:31-43), on add/delete; oldest log = nil
interval_i  = max(0, (dateTime_i − dateTime_(i+1)) / 3600)   // hours

// PlantDashboardViewModel.averageRetained  (:51-54)
avg         = (1/n) · Σ retained_i          // ALL logs, equal weight

// computeNextWaterRecommendation  (:66-86)
if retained_1 ≤ 0            → nil          // "No insights yet"
f           = 1 − g/100                      // g clamped to 0.1…99.9 → f ∈ [0.001, 0.999]
E           = (retained_1 + avg) / 2         // expected retention
Next        = min( E / f , MRC / f )
GoalRunoff  = Next · g / 100

// Log validation (AddWateringLogViewModel.validate, :57-125), in canonical units
0.001 ≤ W ≤ 100     0 ≤ R ≤ W     W − R ≤ 1.05 · MRC     dateTime ≤ now
no other log for the plant in the same calendar minute
temperature −50…60 °C (optional)     humidity 0…100 (optional)

// MRC calculator (CreatePlantViewModel.calculate, :138-190)
MRC_suggested = W_test − R_test   with R_test > 0, R_test ≤ W_test,
                then formatted to display precision ("%.2f" L/gal, "%.0f" mL) into the text field
```

Expanding the blend shows the actual weight each log carries in Next:

```
E = (1/2 + 1/(2n)) · retained_1  +  (1/(2n)) · Σ_(i=2..n) retained_i
```

| n logs | weight on newest log | weight on each older log |
| --- | --- | --- |
| 1 | 1.000 | – |
| 2 | 0.750 | 0.250 |
| 5 | 0.600 | 0.100 |
| 10 | 0.550 | 0.050 |
| 50 | 0.510 | 0.010 |
| 200 | 0.502 | 0.0025 |

Once there are more than a handful of logs, Next is effectively half the latest retained and half the all-time mean. The second-newest log counts as little as the first log of the grow.

## Next-watering recommendation audit

### A. Inputs

**[FACT]** Used: the newest log's `retained`, the mean `retained` of all logs of the plant, plant `goalRunoffPercent`, plant `maxRetentionCapacity` (cap only). "Newest" means the latest `dateTime`, not the most recently entered, so back-dating a log below existing ones does not change `retained_1`.

**[FACT]** Not used: temperature, humidity, the interval between waterings, time since the last watering, date or season, pot size, medium, runoff % as such, water added as such (only through retained), and logs of other plants. The in-app help states that temperature and humidity are "not used in any calculations", which is accurate. The website does not claim environmental adjustment.

### B. History used

All logs, equal-weight arithmetic mean, blended 50/50 with the most recent log. No window, no median, no weighting by recency beyond that blend, no outlier handling.

### C. What the model assumes

The formula is internally consistent if you read `E` as the medium's current *deficit*: the volume it will absorb before draining. Water beyond the deficit becomes runoff. Solving `(W − E) / W = g` for W gives exactly `W = E / (1 − g)`. Under constant demand this has a stable fixed point: if the medium really absorbs E, the next runoff is exactly g, which the existing test `test_nextWater_producesExactGoalRunoff_whenAbsorptionMatchesEstimate` checks. This is sound and matches the protocol: measure in, measure out, and retained is what the medium took.

The model relies on two things the implementation does not guarantee:

- **Each retained value measures the full deficit.** That holds only when the watering produced runoff, meaning the medium reached capacity. With zero runoff, retained equals W, which is a lower bound on the deficit (a censored observation). The app records it as exact.
- **Deficit is roughly stationary.** Real deficit grows with plant size, shrinks after stress or a transplant, and depends on the interval between waterings. The all-time mean assumes stationarity.

### D. Behavior under unusual data

| Case | Behavior in code | Assessment |
| --- | --- | --- |
| Zero logs | Insights shows "No insights yet…" | OK |
| One log | E = retained, Next = retained / f | Reasonable |
| Two logs | Newest weighted 0.75 | OK |
| Many logs | Newest 0.5 plus mean of all; early logs never fade | [P1] lag (ALG-1) |
| Zero runoff | Allowed; retained = W treated as exact | [P1] biased low (ALG-2) |
| Runoff = water added | retained 0 → `nil` → insights hidden | [P1] (ALG-3) |
| Zero water input | Blocked by validation (minimum 0.001 L); init clamps | OK, no division by zero |
| Very high runoff (90%) | Next follows retained down; half weight | Reasonable |
| Very large watering | If retained ≤ 1.05 MRC it is accepted and moves Next by 50% of the jump, then 0.5/n forever | Outlier-sensitive (P2) |
| Retained > 1.05 × MRC | Log rejected | [P1] when MRC is underestimated (MRC-2) |
| Missing temperature or humidity | No effect | OK |
| Changed pot or medium or MRC | Impossible, plants are immutable; user must create a new plant and lose continuity | P1 (MRC-2) |
| Edited log | Impossible; delete and re-add | OK given immutability |
| Deleted log | Dashboard reloads; average and Next recompute; intervals recomputed | OK |
| Goal runoff 50% / 90% / 99.9% | Next = 2× / 10× / 1000× E; cap MRC/f scales the same way | [P2] can exceed the 100 L input limit (ALG-4) |

### E. Numeric edge cases

- **Divide by zero or NaN:** protected. W ≥ 0.001 is enforced, MRC ≥ 0.001 is clamped, f ≥ 0.001 is clamped, and `capacityPercent` guards MRC ≤ 0. A pasted "nan" or "inf" parses with `Double()` but fails every range check.
- **Negative values:** not reachable. Retained is clamped at 0 and runoff at 0.
- **Percentages over 100:** runoff % is capped at 100. Capacity % intentionally caps at 105.
- **Recommendation below zero:** impossible. Next is always > 0 when non-nil.
- **Recommendation above container capacity:** bounded by MRC/f. Because validation already forces retained ≤ 1.05·MRC, E ≤ 1.05·MRC and **the cap can reduce Next by at most about 4.8%**. In practice the cap is nearly inert.
- **Rounding:** display only (`DisplayFormatter`). The exception is the MRC calculator, which writes a rounded string back into the input field (MRC-3).
- **Floating point:** no equality comparisons on derived doubles. The duplicate check compares calendar minutes, not doubles.
- **Stale cache:** none. Values are recomputed per render from `vm.wateringLogs`, which reloads on appear, on sheet dismiss and after delete.

### F. Consistency with the watering protocol

**[FINDING]** The protocol (website steps 1–5 and in-app "Watering Protocol") matches the data captured: measure in, water, collect, measure out, log both. Three mismatches:

1. In-app protocol: "You must always have runoff. Runoff must always be less than Water Added." Validation accepts runoff = 0 and runoff = water added (`Validators.swift:52-54`).
2. The recommendation depends on reaching runoff (see C), but the website protocol page never says to aim for runoff or mentions the goal %.
3. Following Next exactly can drive the grower into zero-runoff waterings on a growing plant (see the matrix below). The recommendation can lead the grower out of its own protocol.

## Algorithm test matrix

**[FACT]** Values below come from a line-for-line port of `WateringLog.init`, `PlantDashboardViewModel.averageRetained` and `computeNextWaterRecommendation`. MRC = 4.5 L (3 gal soil per the website table), goal = 15%. History is listed oldest to newest.

| Scenario | Last W | Last R | History | avg | E | Next | Expected / comment |
| --- | --- | --- | --- | --- | --- | --- | --- |
| First watering | 1.20 | 0.18 | none | 1.020 | 1.020 | 1.200 | Repeats the same watering. Correct. |
| Normal, steady | 1.20 | 0.18 | 4 × (1.20, 0.18) | 1.020 | 1.020 | 1.200 | Stable fixed point. Correct. |
| High runoff (40%) | 1.20 | 0.48 | 4 × steady | 0.960 | 0.840 | 0.988 | Reduces, only halfway. Acceptable. |
| Zero runoff | 1.20 | 0.00 | 4 × steady | 1.056 | 1.128 | 1.327 | Increases 11%, but the true deficit is unknown (≥ 1.2). Should show a warning. |
| Runoff = water added | 1.20 | 1.20 | 4 × steady | – | – | **nil** | Insights vanish. Should fall back to the most recent log with retained > 0 and show a note. |
| Small watering | 0.30 | 0.05 | 4 × steady | 0.866 | 0.558 | 0.656 | A light top-up halves Next. Should probably discount partial waterings. |
| Unusually large | 3.00 | 0.45 | 4 × steady | 1.326 | 1.938 | 2.280 | One outlier nearly doubles Next. |
| Growth trend | 1.90 | 0.28 | 0.34 → 1.62 L retained over 6 logs | 0.840 | 1.230 | 1.447 | Latest demand 1.62 needs about 1.91 L. Next is 24% low, so expect near-zero runoff. |
| Long early history | 2.00 | 0.30 | 30 × 0.34 L retained, 3 × 1.70 | 0.464 | 1.082 | 1.273 | Needs about 2.0 L. Next is 36% low because seedling logs dominate. |
| Missing temperature or humidity | No change; environmental data is not an input |  |  |  |  |  | Correct per documentation |

#### Closed-loop behavior (grower follows Next exactly)

Constant true deficit of 1.2 L, starting from a 0.6 L watering. The app never sees more than W, so it climbs 10–18% per watering:

```
#1  W=0.600 runoff 0.0%     #5  W=0.959 runoff 0.0%     #9  W=1.209 runoff 0.7%
#2  W=0.706 runoff 0.0%     #6  W=1.028 runoff 0.0%     #10 W=1.256 runoff 4.5%
#3  W=0.799 runoff 0.0%     #7  W=1.093 runoff 0.0%     #11 W=1.272 runoff 5.6%
#4  W=0.883 runoff 0.0%     #8  W=1.153 runoff 0.0%     #12 W=1.285 runoff 6.6%   (goal 15%)
```

Demand rising 8% per watering, starting on target: runoff falls to 0% by watering 7 and stays there. Next trails the deficit by about 25% by watering 15.

#### Proposed unit tests (XCTest, pure functions)

```
// Current behaviour, locks in today's algorithm before any change
test_next_singleLog_equalsRetainedOverRetentionFactor()        // 1.20/0.18 → 1.200
test_next_steadyHistory_isFixedPoint()                          // 5×(1.20,0.18) → 1.200
test_next_lastRetainedZero_returnsNil()                         // exists; keep
test_next_manyOldSmallLogs_weightsHalfOnAllTimeMean()           // 30×0.34 + 3×1.70 → 1.273
test_next_capNeverReducesMoreThan5Percent_givenValidation()     // property test over valid inputs
test_next_goal99_9_isBoundedOrRejected()                        // documents ALG-4 until fixed
test_dashboard_averageRetained_usesAllLogs()                    // VM integration, in-memory container
// Validation (AddWateringLogViewModel), none exist today
test_validate_retainedAbove105PercentMRC_rejected()
test_validate_duplicateMinute_rejected_differentMinute_ok()
test_validate_commaDecimal_esES_accepted()                      // after LOC-1 fix
test_validate_errorMessage_usesDisplayUnit()                    // after fix
// After any algorithm change (see Algorithm options)
test_next_zeroRunoffLast_neverBelowLastWaterTimes1_15()
test_next_runoffEqualsWater_fallsBackToLastPositiveRetained()
test_next_recencyWeighting_tracksLinearGrowthWithin10Percent()
test_next_closedLoop_constantDeficit_convergesToGoalWithin5Waterings()
```

Existing tests pass an `averageRetained` that could not come from the log passed in (for example last retained 0.95 with average 0.5 and no other logs). `test_nextWater_lowRunoff_increasesRecommendation` actually recommends 0.853 L after a 1.0 L watering with 5% runoff, which is a decrease compared with the last watering. The name does not describe the behavior. See TEST-3.

## Algorithm concerns

#### [P1] ALG-1: All-time average makes Next lag a changing plant

- **File:** `PlantDashboardViewModel.swift:51-65`; `WateringCalculationService.swift:78`
- **Current:** E = ½·last + ½·mean(all logs). Seedling-stage logs keep equal weight in the mean for the whole grow.
- **Why it matters:** Plants grow. The recommendation undershoots during veg and early flower and overshoots after a demand drop. When it undershoots it produces zero runoff, which breaks the protocol and produces censored data (ALG-2).
- **Evidence:** Simulation (20 seeds, ±10% noise, +6% demand per watering): mean runoff 1.6% against a 15% goal, and 79% of waterings had no runoff. The in-app help at `LocalizedStrings.swift:486` says accuracy improves with more logs, which is the opposite of this behavior.
- **Recommendation:** Replace the all-time mean with a recency-weighted estimate (see options). Update the help text in the same change.
- **Code change:** Yes (algorithm plus strings). Needs product sign-off.

#### [P1] ALG-2: Zero-runoff logs are treated as exact demand

- **File:** `Validators.swift:52-54`; `WateringLog.swift:80`
- **Current:** R = 0 is valid. retained = W is averaged like any other value.
- **Why it matters:** Without runoff the medium may not have reached capacity, so W is only a lower bound on the deficit. Each such log pulls E down and the next watering is likely to have no runoff either.
- **Evidence:** Closed-loop run above: 8 consecutive zero-runoff waterings before any runoff appears.
- **Recommendation:** Keep accepting R = 0 (it is a real measurement) but: (a) after a zero or near-zero runoff watering (under 2%), recommend at least `W_last × (1 + g/100)`; (b) show a one-line note, "No runoff last time. Water until you see runoff."; (c) optionally leave censored logs out of the mean.
- **Code change:** Yes

#### [P1] ALG-3: 100% runoff on the newest log hides all insights

- **File:** `WateringCalculationService.swift:72-73`; `InsightsPanelView.swift:24-37`
- **Current:** retained_1 = 0 returns nil, so the panel shows "No insights yet. Add watering logs…" even though logs exist. The average is hidden too.
- **Why it matters:** The message is misleading and the grower loses guidance right after an unusual watering, which is when they need it. Validation was changed on 2026-03-22 to allow R = W, so this state is reachable in normal use.
- **Recommendation:** Use the most recent log with retained > 0 as "last" and show a note. If no log has retained > 0, show a specific empty-state message. Keep the R = W validation as the owner decided.
- **Code change:** Yes (small)

#### [P2] ALG-4: Goal runoff up to 99.9% produces absurd recommendations

- **File:** `CreatePlantViewModel.swift:95`; `Plant.swift:67`
- **Current:** Any goal from 0.1 to 99.9 is accepted. At 90% the recommendation is 10 × E, and at 99.9% it is 1000 × E. The MRC/f cap grows by the same factor, so it does not help.
- **Why it matters:** A 5 L retained plant at a 90% goal is told to use 50 L, and a 99.9% goal exceeds the app's own 100 L input limit.
- **Recommendation:** Limit the goal to 5–50% (the drain-to-waste practice range is 10–30%), and clamp Next to `AppConstants.waterAddedRange.upperBound`.
- **Code change:** Yes

#### [P2] ALG-5: Single outliers and partial waterings move Next by half their size

- **Current:** The newest log always carries at least 50% weight. A 0.3 L top-up halves Next, and one 3 L flush nearly doubles it (matrix rows above).
- **Recommendation:** Consider when revising ALG-1. A weight of about 0.4–0.5 on the newest log with the rest spread over the last few logs keeps responsiveness and dampens one-offs. Optionally exclude logs flagged as a flush or top-up in the future.
- **Code change:** With ALG-1

#### [P3] ALG-6: Interval is ignored

- **Current:** A watering 1 day after the last and one 4 days after count the same, although deficit scales with time since the last watering.
- **Recommendation:** Consider later: express history as a retained-per-hour rate and predict for the typical interval. Only do this if growers water on irregular schedules. It keeps the measured-history philosophy, since it uses logged timestamps only.
- **Code change:** Consider

## Algorithm improvement opportunities

**[FACT]** What the current algorithm gets right, and any change must keep: it uses only the grower's own measured W and R. It has a clear physical meaning (deficit plus goal runoff). It self-corrects at constant demand. It is explainable in one sentence. Its heavy averaging is good at smoothing stationary noise, and in the pure-noise scenario below it is as good as any alternative.

**[FACT]** Synthetic closed-loop comparison, where the grower follows the recommendation exactly. 25 waterings × 20 random seeds; the first 3 waterings are excluded from scoring. These are models, not field data. Use them to rank options, not to predict real outcomes.

| Candidate (all use only logged W and R) | Constant demand, start low | Constant, ±20% noise | Rising 6% per watering | 40% drop mid-grow |
| --- | --- | --- | --- | --- |
| Current: ½ last + ½ all-time mean | 8.4 pp · 23% zero | 9.0 pp · 12% zero | **13.5 pp · 79% zero** | 10.9 pp · 0% zero |
| Last retained only | 1.5 · 9% | 9.9 · 19% | 7.2 · 12% | 4.3 · 0% |
| EWMA of retained, α = 0.5 | 4.2 · 23% | 9.0 · 12% | 10.0 · 33% | 5.3 · 0% |
| EWMA α = 0.5 + censoring rule (ALG-2) | 2.8 · 9% | 9.2 · 11% | 8.9 · 23% | 5.3 · 0% |
| Holt level + trend + censoring rule | 3.9 · 9% | 9.6 · 13% | **5.6 · 4%** | 6.6 · 9% |
| Runoff feedback: W·(1 + (g − r%)) | 2.1 · 9% | 9.6 · 17% | 7.4 · 13% | 4.3 · 0% |

Cells show the mean absolute distance from the 15% goal in percentage points, then the share of waterings with no runoff. Lower is better for both.

**[RECOMMENDATION]** Proceed in two steps, and get product sign-off before each:

1. **Next revision:** replace the all-time mean with an exponentially weighted mean of retained (α ≈ 0.5, which is roughly the last 3–4 logs). Add the censoring rule (ALG-2), the fallback for retained = 0 (ALG-3), goal bounds and a Next clamp (ALG-4). Keep `E / (1 − g)` and the MRC cap. The change is local to `WateringCalculationService`: move averaging out of the view model into a pure `recommendation(for logs: [WateringLog], plant:)` function so it can be unit tested with realistic histories. Update "What is Next?" help text in EN and ES.
2. **Later, if field logs show sustained lag:** evaluate the trend-aware variant (Holt) on real exported histories before shipping it. It tracks growth best but can overshoot after sudden drops.

Do not add temperature or humidity adjustments. There is no measured basis in the data, and it would move the app away from its measured-history philosophy.

**[RECOMMENDATION]** Show the reasoning on the dashboard, for example "Based on recent retained of 1.02 L and a 15% goal", so growers can see why Next changed. This is cheap and builds trust.

## Unit conversion audit

**[FACT]** Canonical internal units are liters and °C, stored unrounded. Every input path converts display to canonical before validating and storing (`AddWateringLogViewModel:66,76,109,138-144`, `CreatePlantViewModel:84,113`). Every output path converts canonical to display only in `DisplayFormatter`, the chart axes (`HistoryView:340,392,433`) and the export (via `DisplayFormatter`). Constants are correct: 1 US gal = 3.785411784 L (exact), 1 L = 1000 mL, °F = °C × 9/5 + 32. I found no double conversion, no missing conversion, and no case of calculating in display units. Settings changes never touch stored values (tested).

#### [P2] UNIT-1: Range error messages ignore the user's units

- **File:** `LocalizedStrings.swift:345-348`
- **Current:** A mL user sees "must be between 0.001 and 100 liters", and a °F user sees "between -50 and 60 °C".
- **Recommendation:** Format the bounds with `DisplayFormatter` in the active unit (for example "1–100,000 mL", "−58–140 °F").
- **Code change:** Yes

#### [P3] MRC-3: Calculator rounds before storage

- **File:** `CreatePlantViewModel.swift:186-189`
- **Current:** The suggested MRC is written to the text field as `"%.2f"` in the display unit, then parsed on save. In gallons: 1.604 L becomes "0.42" gal, which is 1.590 L (−0.9%).
- **Recommendation:** Keep the unrounded liters value in the view model and use it on save unless the user edits the field. Alternatively show 3 decimals for gallons.
- **Code change:** Yes (small)

Also noted: "gal" is always US gallons, which could confuse UK users (P3). Temperature validation happens after conversion to °C, which is correct.

## Max Retention Capacity

| Aspect | Implementation |
| --- | --- |
| Initial estimate | None in the app. The user types it or uses the calculator. The website reference table is the only source of defaults. |
| Manual entry | Create Plant form, in the display unit, validated 0.001–100 L |
| Automatic calculation | Calculator: `W_test − R_test` (R_test must be > 0) |
| Updated | Never. Plants are immutable. |
| Persisted | `Plant.maxRetentionCapacity`, liters, unrounded (apart from MRC-3) |
| Displayed | Plant Info "Max Capacity"; export "Max Retention" |
| Used in | Capacity % (display), the 105% log validation (hard reject), the Next cap (nearly inert) |
| Affected by history | No. Logs never adjust MRC. |

**[FACT]** Website table check. Every liters to gallons conversion is correct to 1 decimal. The values are fixed fractions of *nominal* pot volume: Coco/Perlite 70/30 = 52.8% (2.0 L per gallon), Coco = 60%, Soil = 40%, scaled linearly from 1 to 10 gal. The app contains no copy of this table, so there is nothing internal to disagree with it, apart from the example data.

#### [P1] MRC-1: Three incompatible definitions of Max Retention Capacity

- **Where:** Website `reference.html:201` ("retains after it has fully drained", which means container capacity from dry). App help `LocalizedStrings.swift:425` and the calculator ("water slowly until runoff starts, then subtract the runoff", which is one watering's retention and depends on how dry the pot was). Example data `GrowListView.swift:262-268`: "Fabric 3 gal", soil, **1.6 L**, shown publicly in `docs/screenshots/06-plant-dashboard.png` as 0.42 gal, while the table on the same website says 3 gal soil = **4.5 L (1.2 gal)**.
- **Why it matters:** Capacity % and the 105% validation mean different things depending on which definition the user followed. With the table value, typical waterings show 20–35% "capacity". With a calculator value measured on a moist pot, later waterings are rejected. The production video plan (`video-watering-protocol-plan.md`) starts from an empty pot with fresh, dry medium, which matches the table, but the app never says so.
- **Recommendation:** Adopt one definition: *the most water the medium can take in one watering, starting from dry* (container capacity). Say "start with dry medium" in the calculator footer, the How To, and the protocol page. Change the example plant to about 4.5 L (or label it a 1 gal pot). Rename the website phrase "saturation levels" (WEB-2). Consider showing the reference estimate in Create Plant, which needs the pot size and medium to be structured choices rather than free text.
- **Code change:** Yes (strings, example data); website text

#### [P1] MRC-2: Immutable MRC plus a hard 105% rule can block valid logs

- **File:** `AddWateringLogViewModel.swift:81-87`; `Plant.swift` (no edit path)
- **Current:** A log with retained > 1.05 × MRC is rejected with "Check your Water Added and Runoff values". MRC cannot be corrected.
- **Why it matters:** Measurements that are correct but exceed an underestimated MRC cannot be recorded. The only remedy is deleting the plant, which permanently deletes all of its history. This is a data-integrity problem driven by UX.
- **Evidence:** MRC 0.8 L from a calculator run on moist medium; a later drier watering of 1.5 L with 0.2 L runoff is rejected.
- **Recommendation:** (1) Add an "Edit Plant" path for MRC and goal runoff at minimum. Capacity % recomputes automatically because it is not stored. (2) Change the 105% rule from a block to a confirmation ("Retained is above this plant's Max Retention Capacity. Save anyway, or update capacity?"). (3) Optionally offer "Update capacity to X" when a log exceeds it.
- **Code change:** Yes. This relaxes the documented immutability for Plant only; logs stay immutable.

## Persistence & data safety

| Event | What happens (from source) | Risk |
| --- | --- | --- |
| Log deleted | Confirmation overlay, `context.delete`, removed from the in-memory array, all intervals recomputed, `save()` | OK. On save failure there is no rollback (DATA-2). |
| Plant deleted | Confirmation, `PlantService.deletePlant`, cascade to logs (tested) | OK |
| Grow deleted | Confirmation, cascade to plants and logs (tested) | OK |
| Log edited | Not possible | N/A |
| Save timing | Explicit `save()` after each insert or delete; SwiftData autosave also on | Good. Nothing is buffered across screens. |
| Backgrounding, termination, crash | Nothing unsaved outside forms, which are intentionally discarded | Low |
| App upgrade | Automatic lightweight migration only; no versioned schema; no test against a real v1.0 store | P1 before the next schema change (DATA-1) |
| iPhone backup and restore | The store is in Application Support, which is included in iCloud and Finder backups; UserDefaults too | OK |
| Reinstall or new phone without backup | All data lost. The text export cannot be imported back. | P2 (DATA-3). The support page states this correctly. |
| Duplicate records | Same-minute duplicates blocked per plant; UUIDs unique | OK |
| Orphans | `Plant.grow` is optional but always set by the UI; cascades prevent orphaned logs | Low |

#### [P1] DATA-1: No versioned schema or migration test before the next model change

- **File:** `EvapotrackApp.swift:47`
- **Current:** `.modelContainer(for: [Grow.self, Plant.self, WateringLog.self])` with implicit lightweight migration.
- **Why it matters:** The next revision adds at least one field (photo filename) and possibly edit support. Adding an optional field with a default is normally a safe lightweight migration. A mistake, such as a non-optional field without a default or a renamed property, fails silently at launch. What the `.modelContainer` modifier does on failure is *unable to determine from current source*; it has to be tested.
- **Recommendation:** Define `SchemaV1` exactly equal to today's models and `SchemaV2` with the new field, plus a `SchemaMigrationPlan` with a lightweight stage. Create the `ModelContainer` explicitly and show an error screen instead of crashing or opening an empty store. Keep a real store file produced by the App Store build as a test fixture and add a migration test.
- **Code change:** Yes

#### [P2] DATA-2: Failed saves leave pending changes in the context

- **File:** `WateringLogService.swift:23-56`, `GrowService`, `PlantService`
- **Current:** On a thrown `save()` the inserted or deleted object stays pending and autosave may commit it later. After "Failed to save", a retry is blocked by the duplicate-minute check, because the unsaved log is already in `plant.wateringLogs`.
- **Recommendation:** Call `modelContext.rollback()` in the catch blocks, and re-sync `plant.wateringLogs` if needed. Replace `try?` in the example-data loader with proper error handling.
- **Code change:** Yes (small)

#### [P2] DATA-3: No restore path except device backup

- **Current:** Export is a padded plain-text report in display units and English, and it cannot be imported.
- **Recommendation:** Consider adding a machine-readable export (CSV per plant or one JSON file in canonical units with UUIDs) and a matching import. Import must not rely on `.unique` upsert silently overwriting rows; decide explicitly between merging and skipping duplicates.
- **Code change:** Consider

## iOS review & user experience

**[FACT]** Strengths: a consistent structure (list, dashboard, history), confirmation before every delete, an entity-limit modal instead of silent failure, the example-data loader for first use, context-aware help, iPad adaptations (full-screen covers, grid columns, width caps), and deliberate Dynamic Type handling (accessibility sizes switch grids to one column and allow three-line titles).

#### [P1] LOC-1: Comma decimal input is rejected

- **File:** `AddWateringLogViewModel.swift:60,71,105,116,130-146`; `CreatePlantViewModel.swift:78,91,106,142,158`
- **Current:** `Double("1,5")` returns nil, so the user sees "Water added must be a number". `.keyboardType(.decimalPad)` shows the region's separator, which is "," in es_ES, es_AR, es_CO, es_CL, de_DE, fr_FR, pt_BR and others.
- **Why it matters:** Users in those regions cannot enter decimal liters or gallons. mL still works. The app is marketed in Spanish.
- **Recommendation:** Parse with a locale-aware parser, for example `try? Double(text, format: .number.locale(.current))`, falling back to accepting either "." or "," as the decimal mark. Put it in one helper used by all six fields. Add tests for en_US, es_ES and de_DE. Also consider trimming whitespace.
- **Code change:** Yes

#### [P2] UX-1: Forced 3-second splash on every cold launch

- **File:** `EvapotrackApp.swift:35-42`; `LaunchView.swift`
- **Current:** Content is hidden for 3 s after every launch, on top of the system launch screen.
- **Why it matters:** Logging happens with wet hands over a tray. Three seconds per session is the largest fixed delay in the app.
- **Recommendation:** Show the animation once, on first launch or after an update, or shorten it to 0.8 s and allow a tap to skip.
- **Code change:** Yes

#### [P2] UX-2: Two sheets bound to the same flag [verify]

- **File:** `PlantDashboardView.swift:160` and `HistoryView.swift:201`
- **Current:** Both views attach `adaptiveSheet(isPresented: $vm.isShowingAddWatering)`. While History is pushed, the dashboard is still in the stack, so tapping + in History asks both to present.
- **Why it matters:** SwiftUI usually presents one and logs "already presenting". The behavior can vary by OS version.
- **Recommendation:** Give HistoryView its own `@State` flag, or keep a single presenter.
- **Code change:** Yes (small)

#### [P3] UX-3: Smaller friction points

- **Items:** 
    - Correcting a log typo means delete, re-enter and reset the date (consider duplicating a log into a pre-filled form).
    - "Reset Settings" has no confirmation and also resets the language.
    - The export completion result is ignored, so failures are silent (`SettingsView.swift:203`).
    - Selecting a log to delete it takes three taps: circle, trash, confirm. A swipe action would be the platform convention.
    - The Add form has no default water amount; pre-filling the Next recommendation as a placeholder would save typing.
- **Code change:** Optional

## Website review

**[FACT]** Six static pages with inline CSS and a shared dark visual style. There are no analytics or trackers in the site's own code, and all pages have title, description and Open Graph tags plus a viewport meta tag and mobile breakpoints. The screenshot carousel uses scroll-snap. The watering-protocol page embeds YouTube in a standard iframe. The homepage self-hosts a 29 MB mp4 with `preload="metadata"`. There is no `robots.txt`, `sitemap.xml`, canonical link or structured data. The dashboard screenshot matches the current UI.

#### [P1] WEB-1: Android support is stated as fact

- **Where:** `index.html:323-324` ("Designed for iPhone, iPad, and Android"), `:331` ("for iPhone, iPad, and Android"), `privacy-policy.html:60,66` ("Android's Room database"), `support.html:89` ("Android 8.0 (Oreo) or later")
- **Current:** Only the hero badge says "Coming Soon". No Android code exists in this repository. Whether an Android codebase exists elsewhere is *unable to determine from current source*.
- **Why it matters:** These are unsupported product claims on the support and privacy pages that App Review and users rely on.
- **Recommendation:** Say "iPhone and iPad. Android coming soon" everywhere. Remove the Room/Android wording from the privacy policy until the Android app ships.
- **Code change:** Website text

#### [P2] WEB-2: "Saturation levels" misdescribes Capacity %

- **Where:** `index.html:312`
- **Current:** Capacity % = this watering's retained ÷ MRC, which is how much of the capacity was refilled. After watering to runoff the medium is at capacity regardless. The reference page was rewritten on purpose to separate retention from saturation.
- **Recommendation:** "See how much of your medium's capacity each watering refilled."

#### [P2] WEB-3: YouTube embed loads Google tracking on the protocol page

- **Where:** `watering-protocol.html:167`
- **Why it matters:** The site's "No tracking" message is about the app, but visitors get YouTube cookies and requests on page load.
- **Recommendation:** Use `youtube-nocookie.com` and a click-to-load poster, or self-host the clip as on the homepage.

#### [P2] WEB-4: The protocol page omits what the recommendation depends on

- **Current:** It does not say to aim for runoff, does not mention the goal %, and does not say to start the MRC test with dry medium.
- **Recommendation:** Add one step, "Aim for runoff every time (your goal %, default 15%)", and a short note on measuring MRC from dry medium.

#### [P3] WEB-5: Internal engineering docs are published on evapotrack.com

- **Where:** `docs/*.md` (Specification, DataModel, Architecture, Requirements, NavigationMap, video plan) inside the Pages root
- **Current:** They are served publicly and are out of date: they say iPad is portrait-only, that example data has one plant, that the example button is "disabled after loading", and that `save()` is private. Commit d8c395b says internal docs were moved out of `docs/`, but these files are there now.
- **Recommendation:** Move them to a non-published directory, and correct them there.

#### [P3] WEB-6: SEO and accessibility polish

- **Items:** Add `robots.txt`, `sitemap.xml`, `<link rel="canonical">` and a `SoftwareApplication` JSON-LD block. Make screenshot alt text descriptive ("Plant dashboard showing retained, capacity and next watering"). "Interactive charts" overclaims, because the chart has overlay toggles but no point selection. Reference table: add `scope` attributes on header cells. Footer copyright color `#3e4a5c` on `#141d2f` is low contrast (about 1.9:1).

## Website ↔ app consistency

| Website statement | Actual app behavior | Consistent? | Required action |
| --- | --- | --- | --- |
| "Designed for iPhone, iPad, and Android"; "Android 8.0 or later"; privacy policy "Room database" | iOS/iPadOS only in this repo | No | Correct the text (WEB-1) |
| "Track up to 30 grows with 25 plants each" | 30 grows, 25 per grow, 750 total | Yes | – |
| "Record water added, runoff collected, temperature, and humidity. Retention and runoff percentages calculated automatically." | Retained volume (not a retention %), runoff %, capacity % | Mostly | Say "retained volume" |
| "Next watering recommendations based on historical patterns and your target runoff percentage" | ½ last + ½ all-time mean, divided by (1 − goal) | Yes | Revisit if the algorithm changes |
| "Interactive charts and overlay toggles" | Toggle pills; no touch selection | Partly | "Charts with temperature and humidity overlays" |
| "Monitor plant saturation levels with capacity percentage" | Capacity % = refill fraction | No | Reword (WEB-2) |
| "Download grow data as a formatted text file… in your preferred display units" | Plain-text .txt via `fileExporter`, display units, English headers | Yes | – |
| "Milliliters, liters, and gallons. Fahrenheit and Celsius. Light and Dark mode. English and Spanish." | All present; Light is called "Day"; Spanish is in-app only (not declared to iOS) | Yes | Declare the `es` localization (LOC-2) |
| "Portrait optimized" | iPhone portrait; iPad all orientations | Yes | – |
| "No accounts. No cloud. No tracking… zero network connections." | No networking APIs, SDKs or entitlements; one external link opens Safari | Yes | Keep true when adding photos |
| "Uninstalling the app removes all stored data" | Correct; device backups keep a copy | Yes | Mention backups when photos ship |
| Reference: MRC = water retained after full drainage (container capacity) | Calculator measures one watering; example 3 gal soil = 1.6 L vs table 4.5 L | No | Unify (MRC-1) |
| Protocol: measure, water, collect, measure, log | Same fields; app help also says "always have runoff" (validation allows 0 and 100%) | Partly | ALG-2/3, WEB-4 |
| Support FAQ: "use the Download Data button" | Download Data section; tap the grow row | Yes | – |
| In-app How To: "Export Data section… Tap Export… system share sheet" | Section is "Download Data"; tap the grow row; system document picker | No | Fix strings (HELP-1) |
| Help: "more logs, more accurate recommendation" | All-time mean lags a growing plant | No | ALG-1 |
| Screenshots (5) | Match the current UI | Yes | Re-shoot after the next revision |

## Photo attachment feasibility

**[FACT]** Context that shapes the design: iOS 17 minimum. Logs are immutable after creation, so a photo is chosen in the Add form and there is no edit screen today. History detail is an inline expanding row, not a separate screen. Deletes happen in three places: log, plant cascade and grow cascade. Export is a text report. The project isolates to the main actor by default. The app has no permission strings and no entitlements.

| API | Verdict | Reason |
| --- | --- | --- |
| **SwiftUI `PhotosPicker`** (PhotosUI, iOS 16+) | **Use** | Native SwiftUI and out-of-process. The app only receives what the user picks. No authorization prompt and no `NSPhotoLibraryUsageDescription`. Supports `matching: .images` and single selection. |
| `PHPickerViewController` | Not needed | Same engine; would need a UIKit wrapper for no benefit on iOS 17. |
| `PHPhotoLibrary` / `PHAsset` | **Avoid** | Requires Photos authorization. Also do not pass `photoLibrary: .shared()` to the picker, because it only adds asset identifiers you would need permission to use. |
| `Transferable` with `FileRepresentation(importedContentType: .image)` | **Use** | The picker copies the original to a temporary file URL, so a 48 MP or ProRAW original is never loaded into memory as `Data`. `loadTransferable(type: Data.self)` would load all of it. |
| ImageIO (`CGImageSource` / `CGImageDestination`) | **Use** | Downsamples during decode (`CreateThumbnailAtIndex`), applies EXIF orientation, and re-encodes without copying metadata. No full-resolution bitmap is created. |
| `UIImage(data:)` then resize | Avoid for import | Decodes the full bitmap first: about 195 MB for 48 MP and 48 MB for 12 MP. |
| Core Graphics | Indirect | Used through ImageIO's `CGImage`; no custom drawing needed. |
| Camera (`UIImagePickerController`, AVFoundation) | **Exclude** | Would require `NSCameraUsageDescription`. Out of scope by requirement. |

## Photo storage recommendation

| Criterion | A: `Data` in the model | A′: `@Attribute(.externalStorage) Data?` | B: file + filename on the model |
| --- | --- | --- | --- |
| Store size | Grows by every photo (1,000 photos ≈ 450 MB inside SQLite) | Small; blobs kept in a hidden sidecar folder | Small |
| Memory | Blob loads with the object; risky in lists | Loaded on property access | Loaded only when a view asks for it |
| Transactional consistency | Full | Full | Needs ordering rules and an orphan sweep |
| Cascade delete | Automatic | Automatic | Manual in 3 services |
| Migration | Heavy migrations copy all image bytes | Lightweight | Lightweight; images untouched |
| Backup (iCloud/Finder) | Included | Included | Included (Application Support) |
| Reinstall | Lost with the store | Lost | Lost; consistent with the store |
| Export (ZIP later) | Read blobs | Read blobs | Copy files directly |
| Corruption isolation | Image and data share fate | Mostly isolated | Fully isolated |
| Transparency and control | Low | Low (framework-managed paths) | High (sizes, cleanup, "delete photos only") |

**[RECOMMENDATION]** **Option B.** Store the image as a file and keep only an optional photo ID on `WateringLog`. Option A is ruled out: embedding images directly in the SQLite store becomes undesirable at hundreds of photos. A′ is a reasonable lower-code fallback if you prefer framework-managed consistency, but B keeps the store small and image-free, makes the future ZIP export and "storage used" display trivial, and a corrupt image cannot affect watering data. The extra work in B (three delete paths and one sweep) is small and testable.

```
Application Support/
  default.store                      (existing SwiftData store)
  WateringPhotos/                    (new; created on first use; backed up)
    3F2A…9C.heic                     detail image, name = new UUID
    3F2A…9C_t.heic                   thumbnail
  WateringPhotos/.incoming/          temp files from the picker; emptied on launch

// SchemaV2 change (lightweight, optional with default)
@Model final class WateringLog {
    …
    var photoFileID: UUID? = nil     // file names derive from it; never store absolute paths
}
```

**Ordering rules** (so a crash can only ever leave an unreferenced file, never a reference to a missing file):

1. **Add:** the photo is processed when picked into `.incoming/`. On Save, atomically move it into `WateringPhotos/`, then insert the log with `photoFileID` and `save()`. If save throws: roll back and delete the moved files. On Cancel: delete the incoming files.
2. **Delete a log:** read `photoFileID`, delete the model, `save()`, and only after success delete the files.
3. **Delete a plant or grow:** collect every descendant `photoFileID` first, delete, `save()`, then delete the files.
4. **Launch sweep** (background, a few seconds after launch): list `WateringPhotos/`, fetch all non-nil `photoFileID`s, delete files nobody references, and empty `.incoming/`. Decide orphans by reference set, not by file date. That avoids the file-timestamp required-reason API.
5. **Missing file:** show a placeholder ("Photo unavailable") and never crash.
6. **Editing** (if added later): write the new file, save the model, then delete the old file. Editing other fields must not touch `photoFileID`.

## Photo size recommendation

```
PhotosPicker(selection:, matching: .images)          // single selection, no photoLibrary
  ↓ item.loadTransferable(type: PickedImageFile.self)   // FileRepresentation → temp URL
  ↓ CGImageSourceCreateWithURL(url, [ShouldCache: false])
  ↓ CGImageSourceCreateThumbnailAtIndex(src, 0, [
        CreateThumbnailFromImageAlways: true,
        CreateThumbnailWithTransform:   true,     // bakes EXIF orientation into the pixels
        ThumbnailMaxPixelSize:          2048,
        ShouldCacheImmediately:         true ])
  ↓ CGImageDestination(.heic) quality 0.70, no properties dictionary → no EXIF/GPS/TIFF
  ↓ same source → 360 px thumbnail, quality 0.60
  ↓ write both to .incoming/  (all of this in a nonisolated async function, off the main actor)
```

| Parameter | Value | Reason |
| --- | --- | --- |
| Detail image, long edge | 2048 px | About 1.5× the width of the largest iPhone screen (1320 px), so pinch-zoom shows leaf detail such as tip burn or spotting. Four times fewer pixels than a 12 MP original. |
| Format | HEIC (JPEG fallback) | About half the size of JPEG at similar quality. Every iOS 17 device can encode it in hardware. Fall back to JPEG 0.75 if the HEIC destination cannot be created. Transcode to JPEG only on export. |
| Quality | 0.70 | Foliage is high-frequency detail; 0.7 avoids visible artifacts at 2048 px. |
| Typical encoded size | 250–600 KB | Plan with 420 KB. |
| Hard size ceiling | 1.5 MB | If exceeded (very noisy low-light images), re-encode once at 0.55, then at 1600 px. |
| Thumbnail | 360 px, q 0.60, ~20–35 KB | Covers a 120 pt preview at @3x. Generated at import so list thumbnails can be added later without a migration. |
| PNG | Never stored | Screenshots and PNGs are re-encoded as HEIC too. |
| Import memory peak | ≈ 13 MB + encoder | 2048 × 1536 × 4 B decoded, compared with about 195 MB for a full 48 MP decode. |
| Display memory | Expanded row ≈ 4 MB; full screen ≈ 13 MB | Decode the preview downsampled to its point size × scale. Keep thumbnails in an `NSCache` with about a 20 MB cost limit. |

### Storage impact

| Logs with a photo | Recommended (HEIC 2048 + thumb ≈ 0.45 MB) | JPEG 2048 q0.75 (≈ 0.8 MB) | Unprocessed 12 MP HEIC (≈ 2.5 MB) | Unprocessed 48 MP (≈ 6 MB) |
| --- | --- | --- | --- | --- |
| 50 | 23 MB | 40 MB | 125 MB | 300 MB |
| 100 | 45 MB | 80 MB | 250 MB | 600 MB |
| 500 | 225 MB | 400 MB | 1.25 GB | 3 GB |
| 1,000 | 450 MB | 800 MB | 2.5 GB | 6 GB |
| 5,000 | 2.25 GB | 4 GB | 12.5 GB | 30 GB |

**Limits.** One photo per log is the structural limit, so no extra per-log cap is needed. A full grow (25 plants watered every 2 days for a 120-day cycle, about 1,500 logs) comes to about 675 MB if every log has a photo. Everything in Application Support counts toward the user's iCloud Backup quota (5 GB on the free tier). That is the engineering reason for *visibility*, not a hard limit: show "Photos: N · X MB" in Settings, computed by summing file sizes in `WateringPhotos/`. Add a "Remove photos from this grow" action later if users ask. I would not add a global cap; there is no reason to pick an arbitrary number.

## Photo UI recommendation

#### Add Watering form

- A new last section, **"Photo (optional)"**, after Environment. It contains one row, a `PhotosPicker` labeled "Add Photo" with a `photo` symbol. Nothing else changes for users who skip it. The keyboard, focus order and Save behave as today.
- After picking: show a small spinner row while processing (about 0.1–0.5 s, longer if the original has to download from iCloud; show that and allow Cancel), then a 120 pt aspect-fit preview with **Replace** (opens the picker again) and **Remove**. Save is disabled only while processing.
- Tapping the preview opens the same expanded viewer described below, so the grower can check the photo before saving.
- Errors appear inline: "Couldn't load this photo. Try another one."

#### History list (collapsed row)

- A small `photo` SF Symbol after the time, in secondary color. Its presence is also added to the row's accessibility label ("has photo"). No thumbnail in v1: it keeps rows the same height, avoids decode work while scrolling, and the collapsed row is meant for quick scanning. Thumbnails are generated anyway so they can be added later.

#### Expanded row (the app's detail view)

- After the field rows: the image at full row width, aspect-fit inside a rounded container with a maximum height of 240 pt (portrait photos letterbox rather than crop, so nothing is hidden).
- Tapping the image opens the expanded photo viewer (below).
- No delete or replace controls here, because logs are immutable. Deleting the log deletes its photo, and the delete confirmation says so when a photo exists.

#### Expanded photo viewer (owner requirement)

**[FACT]** Requirement stated by the owner on 27 Sep 2026: when a watering log has a photo, the user can expand it to fill the screen in a closable view, to look at the plant larger and up close.

- **Opens from:** the image in the expanded history row, and the preview in the Add Watering form.
- **Presentation:** `.fullScreenCover` on iPhone and iPad, on a black background in both Day and Dark mode so the photo is not tinted by the theme. The image starts aspect-fit to the screen, so the whole photo is visible before zooming.
- **Up-close viewing:** pinch to zoom up to 4×, double-tap to zoom to about 2.5× at the tapped point, double-tap again to return to fit, and drag to pan while zoomed. On iOS 17 the most reliable way to get correct pinch anchoring and pan limits is a small `UIScrollView` wrapped in `UIViewRepresentable` (minimum zoom 1, maximum 4, content kept centered).
- **Closing:** a Close button (`xmark`) in the top-trailing corner, at least 44 × 44 pt, always visible. Swipe down closes the viewer when the image is not zoomed. The VoiceOver escape gesture also closes it.
- **Context:** a small caption with the watering's date and time (`log.dateTime.longFormatted`), so the grower knows which watering the photo belongs to.
- **Resolution and memory:** the viewer decodes the stored 2048 px detail file when it opens (about 13 MB decoded) and releases it on close. 2048 px leaves room to zoom about 1.5× before any upscaling on the largest iPhone screen.
- **Orientation:** the iPhone app is portrait-only, so landscape photos appear letterboxed and zoom fills in the detail. On iPad the viewer rotates with the app.
- **Accessibility:** image labeled with its watering date ("Watering photo, Sep 27, 2026 at 9:05 AM") and the hint "Pinch or double tap to zoom". The Close button is labeled "Close photo". With Reduce Motion on, open and close with a cross-fade instead of a zoom animation.
- **Out of scope for v1:** swiping between photos of different logs, sharing or saving the photo, and editing.

## Privacy & permissions

| Item | Today | After the photo feature |
| --- | --- | --- |
| Photos read permission (`NSPhotoLibraryUsageDescription`) | none | **none** (PhotosPicker needs none) |
| Photos add permission (`NSPhotoLibraryAddUsageDescription`) | none | **none** (nothing is saved back to Photos) |
| Camera (`NSCameraUsageDescription`) | none | **none** |
| Entitlements | none | none |
| Network | none | none. If "Optimize iPhone Storage" is on, iCloud may download the original inside the system picker process; the app makes no connection. |
| Privacy manifest | UserDefaults CA92.1 | Unchanged if the sweep decides orphans by reference set. Add `NSPrivacyAccessedAPICategoryFileTimestamp` / `C617.1` only if code reads file dates. Add `DiskSpace` only if it checks free space. Summing file sizes needs neither. |
| App Store privacy label | Data Not Collected | Unchanged (photos never leave the device) |
| Third-party SDKs | none | none (ImageIO, PhotosUI and UniformTypeIdentifiers are system frameworks) |

**[RECOMMENDATION]** **Metadata.** A photo picked from the library can carry GPS coordinates in EXIF, which would reveal where plants are grown. Re-encoding without copying source properties removes all EXIF, GPS, TIFF and maker notes on import, so stored files and anything exported later contain no location. Add a unit test that imports a fixture with GPS and asserts the output has no `{GPS}` dictionary. Update the privacy policy to say optional photos are stored on the device only, with location and camera metadata removed.

## Photo export

**[FACT]** The current export is `DataExportService.exportGrow`, a plain-text String wrapped in `GrowExportDocument` (`.plainText`) and written with `.fileExporter` from Settings.

| Option | Pros | Cons |
| --- | --- | --- |
| A: data plus a photo indicator column | Two-line change; export stays small | Images are not portable |
| B: ZIP with CSV + JPEGs | Real archive and backup path; pairs with DATA-3 | No public zip API in Foundation (use the `NSFileCoordinator` `.forUploading` directory-zip behavior, or write a minimal zip writer). Needs a new `FileDocument` type and progress UI for large grows. |
| C: PDF report with images | Readable | Large, slow, layout work; not re-importable |
| D: exclude images silently | No work | Users may think photos were exported |

**[RECOMMENDATION]** **Next revision: A.** Add a "Photo" column (✓ / —) only when at least one log in the plant has a photo. Leave the existing column layout untouched otherwise, and state in the export footer text that photos are not included. **Later: B**, delivered together with a machine-readable export and import (DATA-3), transcoding HEIC to JPEG with dated file names. Add a snapshot test of the current text export before touching `DataExportService`.

## Performance

**[FACT]** No material problems at current scale. Per-render work is O(n) over one plant's logs: sort, group by day, average, chart mapping. Fetches are small, there is no main-thread I/O besides the SwiftData saves, and there are no timers or observers that leak. Haptic generators are reused.

- [P3] `HistoryView.groupedLogs` and the chart data are recomputed on every body evaluation, including selection taps. Fine up to a few thousand logs; cache in the view model if logs grow further.
- [P3] Catmull-Rom interpolation can draw the retained curve beyond the real data (overshoot) between points. Use `.monotone`.
- [P3] Changing the language rebuilds whole screens with `.id(language)`. This is intentional and fine.
- [P2] Photos: all image decode and encode must run in `nonisolated` async functions, because the target's default isolation is MainActor. Use ImageIO thumbnails, never `UIImage(contentsOfFile:)` for full images in rows. Load file bytes off the main actor. Verify with Instruments (Allocations, Time Profiler) on a 48 MP original on the oldest supported device (iPhone XS / XR).

## Accessibility

#### [P1] A11Y-1: Watering log rows may read "Expand log details" instead of their values [verify]

- **File:** `WateringLogRowView.swift:146-148`
- **Current:** `.accessibilityLabel(isExpanded ? "Collapse log details" : "Expand log details")` is applied to the VStack that holds the time, water, retained and capacity text, without `.accessibilityElement(children:)`.
- **Why it matters:** Depending on how SwiftUI resolves this, VoiceOver either reads only "Expand log details" or repeats it on each child. Either way the history values may be unreachable.
- **Recommendation:** Use `.accessibilityElement(children: .combine)` with a composed label ("9:05 AM, 1.00 L added, 0.90 L retained, capacity 56%, has photo"), keep the expand/collapse as `.accessibilityHint`, and add `.accessibilityAction` for select. Test with VoiceOver.

- [P2] **Contrast (light "Day" mode):** the primary blue `#4a90e2` used for values, section dates and links measures 3.0:1 on the background and 3.3:1 on white. That passes only for large text; body, callout and subheadline need 4.5:1. **Dark mode:** white on `#5da3f5` (Calculate button, help button) is 2.6:1. Recommend a darker light-mode blue (for example `#2f6fbf`, about 5:1) and dark text on the blue buttons in dark mode.
- [P2] **Touch targets:** selection circles (title3 symbol, about 24 pt) and toolbar trash, gear and help buttons have no 44 × 44 pt frame; only the + buttons do. The specification claims 44 pt everywhere.
- [P3] **Chart:** the label only gives a point count. Add `AXChartDescriptorRepresentable` (Audio Graphs) or a label with the min, max and latest values.
- [P3] The Delete and Limit overlays are custom views with `.isModal`. Check that focus moves into them and that the escape gesture dismisses.
- **[FACT]** Good already: labels on every icon button, decorative images hidden, and accessibility sizes reflow to one column.
- **Photo labels:** preview and full-screen image labeled `Strings.wateringPhoto(log.dateTime.longFormatted)`, "Watering photo, Sep 27, 2026 at 9:05 AM" / "Foto de riego, …". The picker row reads "Add photo, optional". The Remove button reads "Remove photo". The viewer's Close button is labeled and the zoom view supports the escape gesture.

## Localization

**[FACT]** All UI strings go through `Strings` (`LocalizedStrings.swift`), a hand-written EN/ES enum switched by an in-app setting, with no `.strings` or String Catalog. Spanish coverage of UI strings is complete. Pluralization is hand-written for "planta/plantas", which is correct for these two languages.

- [P1] LOC-1 comma decimals (above).
- [P2] **LOC-2** Spanish is not declared to iOS: `knownRegions = (en, Base)`, no `es.lproj`, no `CFBundleLocalizations`. The App Store will list English only. System-provided UI (DatePicker, document picker, and later PhotosPicker) follows the *device* language, not the in-app choice. Dates use `formatted()` with the device locale, so an English device with the app set to ES shows English month names. Recommend adding `es` to the project localizations (an empty String Catalog is enough to declare it) and formatting dates with `.locale(Locale(identifier: Strings.current == .spanish ? "es" : "en"))`.
- [P3] **LOC-3** Export text is English-only (`DataExportService.swift:22-114`). `ServiceError.errorDescription` is English but is not shown to users.
- [P3] **HELP-1** The "How to Download" help describes an "Export Data" section, an "Export" button and a share sheet (`LocalizedStrings.swift:441-451`). The UI has a "Download Data" section, the grow row as the button, and a document picker.

#### New strings for the photo feature (EN / ES)

| Key | English | Spanish |
| --- | --- | --- |
| photoSection | Photo (optional) | Foto (opcional) |
| addPhoto | Add Photo | Agregar Foto |
| replacePhoto / removePhoto | Replace / Remove | Reemplazar / Quitar |
| processingPhoto | Preparing photo… | Preparando foto… |
| photoLoadFailed | Couldn't load this photo. Try another one. | No se pudo cargar esta foto. Prueba con otra. |
| photoUnavailable | Photo unavailable | Foto no disponible |
| wateringPhoto(date) | Watering photo, %@ | Foto de riego, %@ |
| hasPhoto | has photo | con foto |
| viewPhotoHint | Double tap to view full screen | Toca dos veces para ver en pantalla completa |
| closePhoto | Close photo | Cerrar foto |
| photoViewerZoomHint | Pinch or double tap to zoom | Pellizca o toca dos veces para ampliar |
| deleteLogMessageWithPhoto(date) | Delete the log from %@ and its photo? This action cannot be undone. | ¿Eliminar el registro de %@ y su foto? Esta acción no se puede deshacer. |
| photoStorage(count, size) | Photos: %d · %@ | Fotos: %d · %@ |
| exportPhotosNote | Photos are not included in the text export. | Las fotos no se incluyen en la exportación de texto. |

Grow and plant delete messages should add "and their photos" when any exist. Singular and plural for the photo count: "1 foto / 2 fotos", using the existing hand-written pattern.

## Testing

**[FACT]** The 152 unit tests cover pure functions well: validators, unit conversion, display formatting, interval recomputation, capacity %, the Next formula, cascade deletes (in-memory container) and settings persistence. Missing:

| Gap | Priority | Proposed tests |
| --- | --- | --- |
| AddWateringLogViewModel validation | [P1] | 105% rule; duplicate minute; optional temperature and humidity parsing; comma decimals; unit conversion on save |
| Recommendation with realistic histories | [P1] | The matrix above, closed-loop convergence, growth tracking, zero or full runoff, goal bounds |
| Migration | [P1] | Open a v1.x store fixture with SchemaV2; assert counts and values; `photoFileID == nil` |
| WateringLogService add and delete | [P2] | Interval recompute, rollback on failure, file cleanup order with photos |
| PlantDashboardViewModel | [P2] | Average, Next and fallback from an in-memory container |
| DataExportService | [P2] | Snapshot of the current text output; photo column only when needed |
| Photo pipeline | [P2] | Max dimension ≤ 2048; orientation baked in (fixture with EXIF orientation 6); `{GPS}` removed; HEIC decodes; size ceiling path; panorama aspect; PNG input |
| PhotoStore | [P2] | Move, delete, sweep; unreferenced files removed; referenced files kept; missing file tolerated |
| UI smoke tests | [P3] | Create grow, plant and log; delete; language switch; Dynamic Type XXXL snapshots; open, zoom and close the photo viewer |
| Test hygiene | [P3] | NavigationTests write to `UserDefaults.standard` of the host app; use a suite name |

**[FINDING]** [P2] **TEST-3** Algorithm tests pass hand-picked `averageRetained` values that could not come from the log histories in the test, and one name (`…lowRunoff_increasesRecommendation`) describes the opposite of what happens relative to the last watering. Move to history-based fixtures when refactoring the algorithm into a function that takes logs.

## Build & release

- [P1] **REL-1** `MARKETING_VERSION = 1.0` and `CURRENT_PROJECT_VERSION = 1` in both configurations, while commits are labeled "v1.1" and the app is live (App Store id 6761138265). App Store Connect rejects an upload whose version and build are not higher than an existing one. Which version is live is *unable to determine from current source*; check App Store Connect and bump before archiving.
- **[FACT]** Signing: automatic, team set. Not reviewed or changed, as instructed.
- **[FACT]** Compiler, concurrency and deprecation warnings are *unable to determine* here (no Xcode). Known-sensitive spots: `nonisolated(unsafe) let plant` in two view models, `nonisolated(unsafe) static var current` in `Strings`, and `Text + Text` concatenation in `HowToView` and `DeleteConfirmationView`, which is deprecated in iOS 26 SDKs in favor of interpolation. Run a Release build with "Treat warnings as errors" once to get a baseline.
- **[FACT]** The iPad supports all orientations; `Specification.md` says portrait only (doc fix). iPhone is portrait only.
- **[FACT]** The privacy manifest is present and correct for current API use. Encryption export is set to NO, which is correct.
- [P3] The target and product are named `EvapotrackDev` (the display name is "Evapotrack"). This is cosmetic but shows up in crash logs and the test module name.

## Technical debt

Ordered by impact on correctness, then reliability, maintainability, performance and user impact. I am not recommending refactors for style alone.

| Sev | Item | Where | Action |
| --- | --- | --- | --- |
| [P2] | Recommendation logic split between the view model (average) and the service (blend), so it is hard to test with real histories | `PlantDashboardViewModel:51-65` | One pure function over `[WateringLog]` |
| [P2] | Numeric parsing duplicated in six places with `Double(text)` | Add Log and Create Plant view models | One locale-aware `NumberInput.parse` helper |
| [P2] | No rollback in service catch blocks | Services | DATA-2 |
| [P3] | The "Saved" overlay is copy-pasted in three forms; the toolbar icon-button style is repeated about 15 times | Create and Add views | Extract when next touched |
| [P3] | Stale comments and docs: `WateringLog.swift:28` says runoff "<"; Specification says portrait-only, "save() is private", "button disabled"; Requirements says portrait-only | Comments and docs | Update |
| [P3] | Magic numbers: 105% factor, goal 15, 3 s launch, 10 chart dots, chart heights. Most are already in `AppConstants`. | Various | Move the rest when touched |
| [P3] | Unused: `Strings.theme`, `themeFooter`; `HistoryView.overlayAxisColor`; `Date.daysBetween`; `WateringLogService.fetchLogs` is a trivial wrapper | Various | Delete |
| [P3] | Force unwrap `URL(string:)!` on a constant | `HowToView.swift:158` | Safe; leave |
| [P3] | Custom `Strings` enum instead of a String Catalog | Utilities | Keep for now. Migrating is a separate project and would change the in-app language switching. |

## Findings register

| ID | Sev | Area | File / symbol | Summary | Code change |
| --- | --- | --- | --- | --- | --- |
| ALG-1 | [P1] | Algorithm | PlantDashboardViewModel.averageRetained; computeNextWaterRecommendation | All-time mean makes Next lag growing plants; zero-runoff spiral | Yes |
| ALG-2 | [P1] | Algorithm | Validators.isValidRunoff; WateringLog.init | Zero-runoff logs treated as exact demand | Yes |
| ALG-3 | [P1] | Algorithm / UX | computeNextWaterRecommendation:72 | 100% runoff on the newest log hides all insights | Yes |
| MRC-1 | [P1] | Concept / website | reference.html; LocalizedStrings:425; GrowListView:262 | Three definitions of MRC; example 1.6 L vs table 4.5 L | Yes + web |
| MRC-2 | [P1] | Data integrity | AddWateringLogViewModel:81-87; Plant | Immutable MRC plus hard 105% block | Yes |
| LOC-1 | [P1] | Input | Add Log and Create Plant view models | Comma decimals rejected | Yes |
| DATA-1 | [P1] | Persistence | EvapotrackApp:47 | No versioned schema or migration test | Yes |
| A11Y-1 | [P1] | Accessibility | WateringLogRowView:146 | Row label may hide values from VoiceOver (verify) | Yes |
| WEB-1 | [P1] | Website | index, privacy-policy, support | Android support stated as fact | Web |
| REL-1 | [P1] | Release | project.pbxproj | Version 1.0 (1) (verify against App Store Connect) | Config |
| ALG-4 | [P2] | Algorithm | CreatePlantViewModel:95 | Goal up to 99.9% gives absurd Next | Yes |
| ALG-5 | [P2] | Algorithm | computeNextWaterRecommendation | Outliers and top-ups move Next by half | With ALG-1 |
| DATA-2 | [P2] | Persistence | Services | No rollback after failed save | Yes |
| DATA-3 | [P2] | Persistence | DataExportService | No import or restore path | Consider |
| UNIT-1 | [P2] | Units | LocalizedStrings:345-348 | Error bounds always in L and °C | Yes |
| UX-1 | [P2] | UX | EvapotrackApp:35-42 | 3 s splash every launch | Yes |
| UX-2 | [P2] | UX | PlantDashboardView:160; HistoryView:201 | Two sheets on one binding (verify) | Yes |
| A11Y-2 | [P2] | Accessibility | Assets: evPrimaryBlue | Light-mode blue text 3.0:1; white on blue 2.6:1 in dark mode | Yes |
| A11Y-3 | [P2] | Accessibility | Row views, toolbars | Touch targets under 44 pt | Yes |
| LOC-2 | [P2] | Localization | project.pbxproj knownRegions | Spanish not declared; dates use device locale | Yes |
| WEB-2 | [P2] | Website | index.html:312 | "Saturation" wording | Web |
| WEB-3 | [P2] | Website privacy | watering-protocol.html:167 | YouTube embed tracking | Web |
| WEB-4 | [P2] | Website | watering-protocol.html | Protocol omits runoff goal and dry-start MRC | Web |
| TEST-1 | [P2] | Tests | EvapotrackDevTests | No view model, service or export tests | Yes |
| TEST-2 | [P2] | Tests | – | No migration test (with DATA-1) | Yes |
| TEST-3 | [P2] | Tests | InsightsAlgorithmTests | Unrealistic fixtures, misleading name | Yes |
| PERF-1 | [P2] | Performance | (photo) | Image work must be nonisolated | With photos |
| DEBT-1 | [P2] | Debt | see table | Split algorithm; duplicated parsing | Yes |
| HELP-2 | [P2] | Help text | LocalizedStrings:486 | "More logs, more accurate" is false | Yes |
| PRIV-1 | [P2] | Privacy docs | privacy-policy.html | Must describe local photos before shipping them | Web |
| EXP-1 | [P2] | Export | DataExportService | Needs a snapshot test before any change | Yes |
| MRC-3 | [P3] | Units | CreatePlantViewModel:186 | Calculator rounds before storage | Yes |
| ALG-6 | [P3] | Algorithm | – | Interval ignored | Consider |
| UX-3 | [P3] | UX | various | Small friction points | Optional |
| A11Y-4 | [P3] | Accessibility | HistoryView chart | No chart descriptor | Optional |
| LOC-3 | [P3] | Localization | DataExportService | Export English-only | Optional |
| HELP-1 | [P3] | Help text | LocalizedStrings:441-451 | Download help names the wrong controls | Yes |
| WEB-5 | [P3] | Website | docs/*.md | Internal docs published and stale | Move |
| WEB-6 | [P3] | Website | all pages | SEO, alt text, contrast polish | Web |
| PERF-2 | [P3] | Performance | HistoryView | Per-body regrouping; Catmull-Rom overshoot | Optional |
| TEST-4 | [P3] | Tests | NavigationTests | Writes to shared UserDefaults | Yes |
| REL-2 | [P3] | Release | project | Warnings baseline unknown; iOS 26 Text+Text deprecation | Check |
| REL-3 | [P3] | Release | project | Target named EvapotrackDev | Optional |
| DEBT-2 | [P3] | Debt | see table | Duplicated overlays, dead code, stale comments | Optional |
| UNIT-2 | [P3] | Units | WaterUnit | "gal" is US only | Optional |
| DATA-4 | [P3] | Persistence | GrowListView.loadExampleData | `try? save()` fails silently | Yes |
| SET-1 | [P3] | UX | SettingsView | Reset has no confirmation; export result ignored | Optional |

## Implementation roadmap

### Phase 1: Correctness

1. Locale-aware number parsing helper used by all numeric fields, with tests (LOC-1).
2. Error messages in the display unit (UNIT-1).
3. Recommendation: move to a pure function over logs; add the retained = 0 fallback (ALG-3), the zero-runoff floor and note (ALG-2), goal bounds of 5–50% and a clamp at 100 L (ALG-4). Lock the current behavior with tests first.
4. With sign-off: recency-weighted estimate (EWMA, α ≈ 0.5) in place of the all-time mean (ALG-1). Update "What is Next?" EN/ES and remove "more logs, more accurate".
5. MRC definition: calculator and help say "start with dry medium"; fix example data (MRC-1); keep the calculator value unrounded (MRC-3).

### Phase 2: Reliability and data integrity

1. SchemaV1 equal to the current models, explicit `ModelContainer` with a migration plan and an error screen; a store fixture from the App Store build; migration test (DATA-1).
2. Rollback on failed saves; remove the silent `try?` (DATA-2, DATA-4).
3. Edit Plant (MRC, goal runoff; optionally name, pot and medium); make the 105% rule a confirmation (MRC-2).
4. Single presenter for the Add sheet (UX-2).
5. Snapshot test of the text export (EXP-1).

### Phase 3: Photo attachment

1. SchemaV2: `WateringLog.photoFileID: UUID? = nil` (lightweight stage); migration test with a v1 fixture.
2. `PhotoStore` (nonisolated): directory management in Application Support, atomic move, delete, reference-set sweep, size total.
3. `ImagePipeline` (nonisolated): ImageIO downsample to 2048 and 360, orientation baked in, HEIC 0.70 with no metadata, JPEG fallback, 1.5 MB ceiling.
4. `PickedImageFile: Transferable` using `FileRepresentation(importedContentType: .image)`.
5. `AddWateringLogViewModel` photo state (none, processing, ready, failed); Save moves incoming to final; Cancel cleans up.
6. `AddWateringLogView`: "Photo (optional)" section with PhotosPicker, preview, Replace and Remove.
7. Deletion: `WateringLogService.deleteLog`, `PlantService.deletePlant`, `GrowService.deleteGrow` collect IDs and delete files after a successful save; update the delete messages.
8. Launch sweep (deferred, background).
9. `WateringLogRowView`: photo indicator in the collapsed row; preview in the expanded row; tap to open the expanded, closable photo viewer (pinch and double-tap zoom, Close button, swipe down to close). The same viewer opens from the Add form preview.
10. Accessibility labels and hints; EN/ES strings (table above).
11. Export: "Photo" column when relevant and a note in the footer.
12. Settings: "Photos: N · X MB".
13. Privacy policy and support FAQ text; confirm Info.plist and entitlements are unchanged and the privacy manifest is unchanged (no file timestamps read).
14. Tests: pipeline (dimensions, orientation, GPS removed), store (move, delete, sweep, missing file), service deletions, view model states, migration.
15. Device checks: 48 MP HEIC, ProRAW, panorama, Live Photo, HDR, screenshot PNG, an iCloud-only original with "Optimize Storage", low storage, airplane mode, VoiceOver, XXXL Dynamic Type, iPad landscape, oldest supported device with Instruments.

### Phase 4: UX, accessibility, localization

1. VoiceOver row fix and verification (A11Y-1); contrast tokens (A11Y-2); 44 pt targets (A11Y-3).
2. Splash once or skippable (UX-1).
3. Declare `es`; locale-aware date formatting (LOC-2); fix download help text (HELP-1).
4. Dashboard line explaining how Next was derived.

### Phase 5: Website and technical debt

1. Remove Android claims (WEB-1); fix "saturation" (WEB-2); privacy-enhanced YouTube (WEB-3); protocol additions (WEB-4); privacy policy photo paragraph (PRIV-1).
2. Move internal `.md` docs out of `docs/` and correct them (WEB-5); robots.txt, sitemap and alt text (WEB-6).
3. Remove dead code; update stale comments; extract the duplicated overlay (DEBT-2).
4. Bump the version and build; get a warnings baseline (REL-1, REL-2).

## What should actually change in the next EvapoTrack revision?

### Must fix

- Comma-decimal input parsing (LOC-1)
- Insights fallback when the newest log has 100% runoff (ALG-3)
- Zero-runoff floor and note (ALG-2)
- Edit Plant for MRC and goal; 105% rule becomes a confirmation (MRC-2)
- One MRC definition in app help, calculator and example data (MRC-1)
- Versioned schema, explicit container, migration test, before any model change (DATA-1)
- Rollback on failed saves (DATA-2)
- Verify and fix VoiceOver on log rows (A11Y-1)
- Remove Android claims from site, privacy and support (WEB-1)
- Version and build bump (REL-1)

### Should fix

- Recency-weighted recommendation plus help text, after sign-off (ALG-1, HELP-2)
- Goal runoff bounds and a Next clamp (ALG-4)
- **Optional watering-log photos** as specified in Phase 3
- Error messages in display units (UNIT-1)
- Splash once or skippable (UX-1); single Add sheet presenter (UX-2)
- Contrast and touch targets (A11Y-2, A11Y-3)
- Declare Spanish; localized dates (LOC-2)
- Website: saturation wording, privacy-enhanced YouTube, protocol additions, privacy policy photo text
- View model, service, export and photo tests; realistic algorithm fixtures

### Consider

- Machine-readable export and import (restore path), later ZIP with photos
- Trend-aware (Holt) recommendation, tested on real exported histories
- Interval-normalized demand
- List thumbnails; chart point selection; Audio Graph
- Structured pot and medium choices that pre-fill MRC from the reference table
- Duplicate-log-to-form for fixing typos
- Moving internal docs out of the public site; SEO files

### Do not change

- Canonical liters and °C stored unrounded; display-only rounding
- Retained, runoff % and capacity % formulas
- `E / (1 − goal)` structure and the measured-history basis; no environmental "adjustments"
- Local-only storage, zero networking, no SDKs, no accounts
- Watering log immutability (photo chosen at creation)
- Cascade delete rules and entity limits
- In-app EN/ES `Strings` mechanism, for now
- The existing text export layout (add to it only)
- Signing, App Store metadata

Sources: repository `evapotrack/evapotrack` at `89cc8c8`. The simulations are line-for-line ports of `WateringLog.init`, `PlantDashboardViewModel` and `WateringCalculationService` in Python with synthetic demand. Contrast ratios are computed from `Assets.xcassets` color values with the WCAG 2.x formula. Nothing in the repository was modified.
