# EvapoTrack Revision 2: Detailed Change Log

This document describes, for every file changed since the baseline, **what existed before** and **what exists now**, why it changed, and how it is tested.

| | |
|---|---|
| Baseline | `89cc8c8` "Add 8.5x11 print-ready desk display flyer with QR code". This is the code the 2026-09-27 engineering review audited. |
| Branch | `claude/wonderful-edison-i0ukly` |
| Scope | 12 commits, 88 files, about 6,100 lines added and 1,140 removed (not counting the archived reports and research in `engineering/`) |
| Build status | **Not compiled and no tests run.** The environment had no Swift toolchain: download.swift.org was blocked by the network policy. Every Swift file passed a tree-sitter syntax parse. The one flagged line (`SettingsView.swift`, `as? String ?? "1"`) is unchanged shipped code and a known parser false positive. |

Reproduce any section with `git diff 89cc8c8 -- <path>` or `git show <commit>`.

---

## Contents

1. [Commit list](#1-commit-list)
2. [Recommendation (Next) algorithm](#2-recommendation-next-algorithm)
3. [Max Retention Capacity, Edit Plant, over-capacity logs](#3-max-retention-capacity-edit-plant-over-capacity-logs)
4. [Number input and unit-aware messages](#4-number-input-and-unit-aware-messages)
5. [Data model, schema versioning and migration](#5-data-model-schema-versioning-and-migration)
6. [Save failures and example data](#6-save-failures-and-example-data)
7. [Watering photos](#7-watering-photos)
8. [Export](#8-export)
9. [Accessibility and localization](#9-accessibility-and-localization)
10. [Help text and strings](#10-help-text-and-strings)
11. [Website and privacy policy](#11-website-and-privacy-policy)
12. [Internal documentation](#12-internal-documentation)
13. [Tests](#13-tests)
14. [Project file](#14-project-file)
15. [Files not changed on purpose](#15-files-not-changed-on-purpose)

---

## 1. Commit list

| # | Commit | Title | Audit IDs |
|---|---|---|---|
| 1 | `f1e6d9d` | Characterize the current Next algorithm with history-based tests | TEST-3 |
| 2 | `95bd719` | Replace the Next algorithm with a pure, explainable RecommendationEngine | ALG-1…5, DEBT-1, HELP-2 |
| 3 | `d21df19` | Parse numbers with the region's decimal separator; show limits in user units | LOC-1, UNIT-1 |
| 4 | `a9f838e` | Version the SwiftData schema and open the store explicitly | DATA-1, TEST-2 |
| 5 | `3c9336d` | Roll back failed saves in every service; report example-data failures | DATA-2, DATA-4 |
| 6 | `1906e6e` | Unify Max Retention Capacity; add Edit Plant; confirm over-capacity logs | MRC-1…3, ALG-4 |
| 7 | `978971b` | Pin the grow export format with snapshot tests before changing it | EXP-1 |
| 8 | `c5a1b67` | Add optional watering-log photos with a full-screen, zoomable viewer | Photos, PERF-1, A11Y-1 |
| 9 | `4776130` | Improve contrast, tap targets, chart and language accessibility | A11Y-2…4, UX-2, LOC-2 |
| 10 | `4d3dc6b` | Correct the website and privacy policy; move internal docs out of docs/ | WEB-1…6, PRIV-1 |
| 11 | `562925a` | Fix Download help naming controls that don't exist | HELP-1 |
| 12 | `c648c1f` | Archive the engineering review, research and change documentation | — |
| 13 | (next) | Add CLAUDE.md orientation for future sessions | — |

---

## 2. Recommendation (Next) algorithm

### 2.1 `Evapotrack/Services/WateringCalculationService.swift` (modified)

**Before**, the service held three things:
- `recalculateIntervalHours(for:)`: sorts logs by date. The oldest gets `nil`, and each later log gets the hours since the previous one.
- `capacityPercent(retained:maxRetentionCapacity:)`: `min(retained / MRC × 100, AppConstants.maxCapacityPercent)`, **capped at 105%**.
- `struct NextWaterRecommendation { next, goalRunoff, goalRunoffPercent }` and `computeNextWaterRecommendation(lastLog:averageRetained:maxRetentionCapacity:goalRunoffPercent:)`:
  1. `guard lastLog.retained > 0 else { return nil }`. If the newest log had 100% runoff, **all insights disappeared**.
  2. `expected = (lastRetained + averageRetained) / 2`, where `averageRetained` was the mean of **all logs ever**, computed in the view model.
  3. `next = expected / (1 − goal/100)`, capped at `MRC / (1 − goal/100)`.
  4. `goalRunoff = next × goal/100`.

  Zero-runoff logs were averaged in as exact demand even though they only prove "at least this much". Goals up to 99.9% were accepted, which made `1 − goal` tiny and Next enormous.

**After:**
- `recalculateIntervalHours` is unchanged.
- `capacityPercent` is **no longer capped**: `guard MRC > 0, retained.isFinite else { return 0 }; return max(0, retained / MRC × 100)`. A value above 100% now tells the grower the capacity may be set too low (see §3), instead of hiding it at 105%.
- `NextWaterRecommendation` and `computeNextWaterRecommendation` are **removed**. The logic moved to `RecommendationEngine`.

**Why:** ALG-1 (all-time mean lags growth), ALG-2 (zero runoff treated as exact), ALG-3 (100% runoff hid insights), ALG-4 (goal bounds), ALG-5 (a single outlier moved Next by half), DEBT-1 (algorithm split between a view model and a service).

### 2.2 `Evapotrack/Services/RecommendationEngine.swift` (new, 272 lines)

A pure, `nonisolated` module with no SwiftData or UI dependencies, so it is fully unit-testable.

- `WateringObservation { waterAdded, runoff, date }` is the engine's input. The view model maps each `WateringLog` to one.
- `ObservationKind` classifies each watering:
  - `.measured(retained)` when 0 < runoff < water. Retained equals what the medium absorbed before draining.
  - `.noRunoff(waterAdded)` when runoff = 0. This is **censored**: the plant needed at least this much.
  - `.fullRunoff` when runoff ≥ water. Nothing was retained, so it says nothing about demand and is skipped.
  - `.invalid` for non-finite or non-positive values.
- Estimator: a Holt level with a damped trend over the chronological history.
  - Constants: `levelSmoothing` α = 0.5, `trendSmoothing` β = 0.2, `trendDamping` φ = 0.8.
  - `forecast = level + clamp(φ·trend, ±25% of level)`.
  - For each measured watering: `effective = max(retained, forecast × 0.75)`. This is `maxDropPerWatering` = 0.25, so a top-up or unusual watering can lower the estimate by at most a quarter. Then `level' = α·effective + (1−α)·forecast` and `trend' = β·(level'−level) + (1−β)·φ·trend`.
  - The first measured watering sets the level directly (trend 0).
  - A no-runoff watering raises the level to W only if W > forecast (trend = max(trend, 0)). Otherwise it is ignored.
- Result: `estimate = min(forecast, MRC)` → `next = estimate / (1 − goal)`.
  - `goal = effectiveGoal(requested)`, clamped to 5–50%, with NaN → 15%.
  - `next` is capped at 100 L, the largest loggable watering.
  - `goalRunoff = next × goal`.
- `RecommendationOutcome`: `.noHistory`, `.noUsableData` (every watering drained completely), or `.recommendation(Recommendation)`.
  - `Recommendation` carries `nextWater, goalRunoff, goalRunoffPercent, estimatedRetention, basis, notes`.
  - `basis` is `.measured(wateringsWithRunoff:)` or `.noRunoffYet`.
  - `notes` can include `lastWateringNoRunoff(raisedEstimate:)`, `lastWateringFullRunoff`, `demandRising`/`demandFalling` (trend at least 5% of level), `limitedByCapacity`, `goalAdjusted`, and `limitedByMaximumWater`.
- Observations are sorted by date. Equal dates keep their input order.

**Why this model:** see `engineering/research/algorithm/README.md`. In 18 simulated scenarios with the grower following Next, the mean distance from goal runoff fell from 9.9 to 6.2 percentage points and waterings with zero runoff fell from 34.4% to 9.7%. Recovery from a wrong start or a demand step took 5–6 waterings instead of 14–30. Trade-offs, stated honestly: under heavy random noise (±20–30%) and irregular schedules (S8), the engine produces more waterings above 2× the goal than the old model did.

### 2.3 `Evapotrack/Utilities/RecommendationText.swift` (new)

`RecommendationText.lines(for:unit:)` turns the basis and notes into localized sentences in the grower's water unit (for example, "Your last watering (1.10 L) produced no runoff, so Next was increased to help reach runoff."). Before, nothing explained Next.

### 2.4 `Evapotrack/ViewModels/PlantDashboardViewModel.swift` (modified)

- **Before:** `averageRetained` (mean of all logs) and `nextRecommendation`, which called the service with the newest log and that average. The header said "No editing of plants or logs is allowed."
- **After:** a single `var recommendation: RecommendationOutcome`, computed by the engine from all logs through a private `WateringLog.observation` mapping. `averageRetained` and `nextRecommendation` are removed. The header comment was updated because plants are now editable.

### 2.5 `Evapotrack/Views/PlantDashboard/InsightsPanelView.swift` (modified)

- **Before:** a three-cell grid of **Average** (all-time mean retained), **Next**, and **Goal (x%)**. If the newest log had 100% runoff or there were no logs, it showed only "No insights yet. Add watering logs to see recommendations."
- **After:** it takes `outcome: RecommendationOutcome`.
  - A recommendation shows a grid of **Expected** (estimated retention), **Next**, and **Goal (x%)**, plus the explanation lines under the grid.
  - `.noHistory` shows "No watering logs yet. Log water added and runoff to get a recommendation."
  - `.noUsableData` shows "Not enough runoff data yet: every watering so far drained completely…".
  - "Average" was dropped because the estimate is no longer an average.

### 2.6 `Evapotrack/App/AppConstants.swift` (modified)

| Before | After |
|---|---|
| `enum AppConstants` (main-actor by default) | `nonisolated enum AppConstants`, so pure code (engine, parser, photo processing) can read it off the main actor |
| `maxCapacityPercent = 105.0` (Capacity % cap) | removed (Capacity % is uncapped) |
| `maxRetainedFactor = 1.05` (hard rejection) | replaced by `retainedConfirmationFactor = 1.05` (asks for confirmation, §3) |
| (none) | `goalRunoffPercentRange = 5.0...50.0`, with a comment on the rationale: below 5% is too close to zero to measure, and above 50% wastes more than it retains |
| (none) | `photoDetailMaxPixelSize = 2048`, `photoThumbnailMaxPixelSize = 360` |

`targetRunoffPercent = 15.0`, the entity limits, ranges and keys are unchanged.

---

## 3. Max Retention Capacity, Edit Plant, over-capacity logs

### 3.1 One definition everywhere

**Before**, the app and site used three definitions:
- the app's field description: "The maximum volume of water the medium can hold before runoff begins";
- the calculator footer: "derive it from a test watering", with no mention of dry medium;
- the reference page: "…hold before runoff begins… after it has fully drained".

The example plants used 1.6 L and 2.1 L, while the reference table lists about 1.5 L for 1 gal soil and about 2.3 L for 1 gal coco.

**After**, the definition is: *the most water the medium takes in during one watering, **starting from dry**, before runoff begins* (container capacity). It is used in:
- `Strings.maxRetentionDescription`, `calculatorFooter`, `editCapacityFooter`;
- How To › "What Is Max Retention Capacity?" (EN/ES, rewritten), and How To › Watering Protocol;
- `docs/reference.html` intro and tip, and the `docs/watering-protocol.html` tip;
- the example data: 1 gal soil 1.5 L and 1 gal coco 2.3 L, following the reference table.

The resulting example Capacity % values are 45–87% for soil and 50–63% for coco. During the session I said "60–87%" for soil; that was wrong.

### 3.2 `Evapotrack/ViewModels/PlantFormViewModel.swift` (new; replaces `CreatePlantViewModel.swift`, deleted)

**Before (`CreatePlantViewModel`):**
- Create only.
- `Double(text)` parsing, so comma decimals were rejected.
- Goal accepted 0.1–99.9.
- The calculator wrote `String(format: "%.<precision>f", retained)` back into the text field, so the **rounded display value was persisted**. For example, 0.3784 gal was stored as 0.38 gal. It accepted runoff ≥ water, which gives a capacity of 0 or less.

**After (`PlantFormViewModel`):**
- `enum Mode { case create(Grow?); case edit(Plant) }`. `configure(modelContext:waterUnit:)` prefills the fields in edit mode.
- Unrounded values are kept: `capacitySource` and `goalSource` remember the exact value behind the text. If the text is unchanged at save time, the exact value is stored. Typing a new value replaces it.
- Uniqueness checks the name within the grow, excluding the plant being edited.
- Goal: blank means 15%. A new or changed goal must be 5–50%. An **unchanged legacy goal** outside that range (for example 60% from before) is kept as is, and the engine clamps it and shows `goalAdjusted`.
- Calculator: requires 0 < runoff < water (`Strings.calculatorRunoffTooLarge`) and uses `NumericInput`.

### 3.3 `Evapotrack/Views/PlantForm/PlantFormView.swift` (renamed from `Views/CreatePlant/CreatePlantView.swift`)

- **Before:** `CreatePlantView(grow:)`, titled "Add Plant". The Calculate button used white text on blue.
- **After:** `PlantFormView(mode:)`, titled "Add Plant" or "Edit Plant". Edit mode shows a footer: "Changing the capacity keeps every watering log as measured…". The Calculate button text uses `Color.evOnPrimary`.

### 3.4 `Evapotrack/Services/PlantService.swift` (modified)

- **Before:** add, fetch, delete, each with a plain `try modelContext.save()`.
- **After:**
  - `updatePlant(_:name:potSize:mediumType:maxRetentionCapacity:goalRunoffPercent:)` added. Logs are untouched.
  - All saves use `saveOrRollback` (§6).
  - `deletePlant` collects photo IDs first and deletes the files after the save succeeds (§7).
  - The initializer gains `photoStore:` and `save:` parameters with defaults, for tests.

### 3.5 `Evapotrack/Views/PlantDashboard/PlantDashboardView.swift` (modified)

- **Before:** no way to change a plant.
- **After:** an **Edit** button (44 pt) in the Plant Info header opens `PlantFormView(mode: .edit(vm.plant))` in an adaptive sheet. `HistoryView`/`HistoryPanelView` no longer take `maxRetentionCapacity`; they read it from the plant, so an edit is reflected immediately.

### 3.6 Over-capacity watering logs (`AddWateringLogViewModel.swift`, `AddWateringLogView.swift`)

- **Before:** if retained > 1.05 × MRC, saving was **refused** with "Retained volume exceeds 105% of Max Retention Capacity…". Because MRC could not be edited, a grower with an underestimated capacity could not log real waterings at all.
- **After:** `validate(confirmedOverCapacity:)` runs every hard check first. The capacity check comes last and, instead of failing, sets `isShowingCapacityConfirmation` and `capacityConfirmationMessage`: "This watering retained X, more than this plant's Max Retention Capacity (Y). Check Water Added and Runoff. If they're right, the capacity may be set too low; you can edit it from the plant's dashboard." The alert offers **Save Anyway** and **Review**.

### 3.7 `Evapotrack/Views/PlantList/PlantListView.swift`, `HistoryPanelView.swift` (modified)

- `PlantListView` now uses `PlantFormView(mode: .create(grow))` instead of `CreatePlantView(grow:)`.
- `HistoryPanelView` no longer passes `maxRetentionCapacity`.

---

## 4. Number input and unit-aware messages

### 4.1 `Evapotrack/Utilities/NumericInput.swift` (new)

- **Before:** eight numeric fields used `Double(text)`, which accepts only "." as the decimal mark. In comma-decimal regions (Spain, Germany, France, Brazil…) the decimal pad types ",", so "1,5" was rejected as "must be a number".
- **After:** `NumericInput.parse(_:locale:)`:
  - Accepts both "." and ",".
  - When both appear, the last one is the decimal mark.
  - A repeated separator must group digits in threes.
  - A single separator is a decimal mark, unless it is the locale's grouping separator followed by exactly three digits (with a first group that doesn't start with 0).
  - Spaces, NBSP, narrow NBSP, thin space and apostrophes count as grouping.
  - Only ASCII digits are allowed: no exponent, nan, inf or hex.
  - Used by the Add Watering form (water, runoff, temperature, humidity) and the plant form (capacity, goal, calculator water and runoff).

### 4.2 `Evapotrack/Services/ValidationService.swift`, `Utilities/DisplayFormatter.swift`, `Utilities/LocalizedStrings.swift`

- **Before:** range errors were fixed strings in liters and °C: "Water added must be between 0.001 and 100 liters.", "Temperature must be between -50 and 60 °C." A grower using mL or °F saw limits in other units.
- **After:**
  - `validateMaxRetention(_:unit:)`, `validateWaterAdded(_:unit:)` and `validateTemperature(_:unit:)` format their limits with `DisplayFormatter.waterLimit(_:unit:roundingUp:)` and `temperature`.
  - The minimum rounds up, adding decimals while the shown value is more than 1.5× the real one. The maximum rounds down, so the value shown is always itself valid: "1 mL"–"100000 mL", "0.001 L"–"100.00 L", "0.0003 gal"–"26.41 gal", "-58.0 °F"–"140.0 °F".
  - The strings are now functions: `waterAddedRange(min:max:)`, etc.

### 4.3 `Evapotrack/Services/UnitConversionService.swift`

The only change is `enum` → `nonisolated enum`, so it can be used from pure code. The conversion math is unchanged.

---

## 5. Data model, schema versioning and migration

### 5.1 `Evapotrack/Models/SchemaV1.swift` (new, frozen)

A byte-for-byte model copy of the shipped store (`Grow`, `Plant`, `WateringLog` as they were at the baseline, including `goalRunoffPercent = 15.0` and `createdAt = Date()` defaults), declared as `SchemaV1: VersionedSchema` version 1.0.0. It must never change. The model files last changed on 2026-03-21, before the first App Store upload, so this matches every installed store.

### 5.2 `Evapotrack/Models/Schema.swift` (new)

`SchemaV2` (2.0.0) lists the current models. `typealias Grow/Plant/WateringLog = SchemaV2.…` keeps all existing code unchanged. `EvapotrackMigrationPlan` has one `.lightweight(fromVersion: SchemaV1, toVersion: SchemaV2)` stage.

### 5.3 `Grow.swift`, `Plant.swift`, `WateringLog.swift` (modified)

- **Before:** top-level `@Model final class` declarations.
- **After:** `extension SchemaV2 { @Model nonisolated final class … }` with identical stored properties and initializers, except:
  - `WateringLog` adds `var photoFileID: UUID? = nil` and an init parameter `photoFileID: UUID? = nil`. It is optional with a default, so lightweight migration fills existing rows with `nil`.
  - The comments state that plants are editable and logs are not.

### 5.4 `Evapotrack/Services/PersistenceController.swift` (new) and `App/EvapotrackApp.swift` (modified)

- **Before:** `.modelContainer(for: [Grow.self, Plant.self, WateringLog.self])` on the WindowGroup, with no schema version, no migration plan and no error handling. If the store failed to open, SwiftUI's default container setup crashed at launch.
- **After:**
  - `PersistenceController.makeContainer()` opens the store with `Schema(versionedSchema: SchemaV2.self)` and the migration plan. If that fails, it logs the error and retries with automatic (inferred) migration, which covers a store from an unknown older model.
  - `makeInMemoryContainer()` is provided for tests.
  - `EvapotrackApp` keeps a `Result<ModelContainer, Error>`: success shows the app, and failure shows the new `DataStoreErrorView` instead of crashing or silently starting empty.

### 5.5 `Evapotrack/Views/Components/DataStoreErrorView.swift` (new)

The screen shown when the store can't be opened: "Your data couldn't be opened… Nothing has been deleted. Close the app completely and open it again… Don't delete the app. That would remove your data." It is available in EN and ES.

### 5.6 `Evapotrack/Utilities/Logger.swift` (modified)

The static loggers are marked `nonisolated` so pure code can log. A `photos` category was added.

---

## 6. Save failures and example data

### 6.1 `Evapotrack/Services/ServiceError.swift` (modified)

- **Before:** only `ServiceError.limitExceeded`.
- **After:** also `typealias SaveHandler = (ModelContext) throws -> Void` and `ModelContext.saveOrRollback(using:action:)`. On failure it calls `rollback()`, logs the error, and rethrows.

### 6.2 `GrowService.swift`, `PlantService.swift`, `WateringLogService.swift` (modified)

- **Before:** `insert` or `delete`, then `try modelContext.save()`. A failed save left the inserted or deleted object pending in memory, and autosave could commit it later. After a failed add, the log stayed in `plant.wateringLogs`, so retrying was rejected as a duplicate timestamp.
- **After:**
  - Every save goes through `saveOrRollback`.
  - `addLog` also removes the unsaved log from the plant's array on failure.
  - Identity comparisons use `===`.
  - Each service accepts `save:` (for failure injection in tests) and `photoStore:`.

### 6.3 `Evapotrack/Services/ExampleDataService.swift` (new) and `Views/GrowList/GrowListView.swift` (modified)

- **Before:** `GrowListView.loadExampleData()` built one grow with two plants (MRC 1.6 and 2.1 L) and six logs each inline in the view, then called `try? modelContext.save()`. A failure was silently ignored.
- **After:** `ExampleDataService.loadExampleGrow()` builds the same shape, with capacities corrected to 1.5 L and 2.3 L (§3.1), explicit relationship appends, interval recalculation and one `saveOrRollback`. On failure nothing is kept and `GrowListView` shows "Couldn't load the example grow. Please try again."

---

## 7. Watering photos

The complete feature is in commit `c5a1b67`. The summary of design decisions:

| Topic | Decision |
|---|---|
| Picker | SwiftUI `PhotosPicker(selection:matching: .images)`. It runs out of process, so **no Photos permission**, no `NSPhotoLibraryUsageDescription`, and only the chosen photo is shared. |
| Camera | Not used. No AVFoundation, `UIImagePickerController` or `PHPhotoLibrary`. |
| Transfer | `PickedImageFile: Transferable` with `FileRepresentation(importedContentType: .image)`, which copies the file into `.incoming/<launch>/` instead of loading a 50 MB original into memory. |
| Processing | `PhotoProcessor` (ImageIO, `Task.detached`): `CGImageSourceCreateThumbnailAtIndex` with FromImageAlways, WithTransform (orientation baked in) and ShouldCacheImmediately. The detail image is ≤ 2048 px and the thumbnail ≤ 360 px (made from the detail image). |
| Encoding | HEIC at quality 0.70, with JPEG at 0.70 if HEIC encoding fails. If the result is over 1.5 MB, quality drops to 0.55, then the size to 1600 px. |
| Metadata | `CGImageDestinationAddImage` receives only the compression quality, **no metadata dictionary**, so EXIF, GPS, TIFF make/model and maker notes are never written. A test proves this with a GPS-tagged fixture. |
| Storage | `Application Support/WateringPhotos/<uuid>.heic` and `<uuid>_thumb.heic` (or `.jpg`). The model stores only `photoFileID: UUID?`, never a path, so a backup restored to a new device still works. `.incoming` is excluded from backups. |
| Add order | Copy into place → save the log → remove the incoming copy. A failed save removes the placed copy and keeps the prepared one for a retry. |
| Delete order | Save the deletion of the log, plant or grow first, then delete the files. |
| Crash cleanup | `PhotoMaintenance.removeOrphanedFiles` runs at launch on the main actor. It removes files whose ID no log has, and `.incoming` folders from earlier launches. It compares IDs only, uses no file dates, and so needs no required-reason API. It does nothing if the store fetch fails. |
| Missing file | The thumbnail and viewer show "Photo unavailable", and the log stays fully usable. |
| Migration | `photoFileID` is the only V1→V2 change (§5). |
| Export | A Photo column and a footer note when photos exist (§8). |

### 7.1 New files

- `Services/Photos/PhotoStore.swift`: `PreparedPhoto`, `PhotoUsage`, `PhotoStore` (commit, deletePhoto, discard, sweep, usage, photoID(fromFileName:), detailURL/thumbnailURL lookups).
- `Services/Photos/PhotoProcessor.swift`: `process(sourceURL:outputDirectory:id:limits:)`, `downsample`, `encode`, `Limits`, `ProcessingError`, `EncodedFormat`.
- `Services/Photos/PickedImageFile.swift`: the Transferable wrapper.
- `Services/Photos/PhotoImageLoader.swift`: `PhotoSource` (`.stored(UUID)` / `.prepared(PreparedPhoto)`), off-main decoding, and `PhotoThumbnailCache` (NSCache, 24 MB).
- `Services/Photos/PhotoMaintenance.swift`: the launch cleanup.
- `Views/Photos/WateringPhotoThumbnail.swift`: an async, cached thumbnail with a "Photo unavailable" fallback.
- `Views/Photos/PhotoViewer.swift`:
  - `PhotoViewerItem` and `PhotoViewer`, a full-screen black cover showing the date while not zoomed.
  - `ZoomableImageView`/`ZoomingScrollView` (UIScrollView): pinch zoom 1–4×, double-tap to zoom at a point or back out, and pan while zoomed.
  - Close with the X button (44 pt), a swipe down when not zoomed, or the VoiceOver escape gesture.
  - No slide animation when Reduce Motion is on. The view refits on rotation.

### 7.2 Modified files

- `ViewModels/AddWateringLogViewModel.swift`:
  - Before: the form state, validation and save only.
  - After:
    - `PhotoState` (`.empty`, `.processing`, `.ready(PreparedPhoto)`, `.failed`) and `loadPhoto(_:)`. Processing runs detached, and a stale result (a newer pick, or the form closed) is discarded by request ID.
    - `removePhoto()` and `discardUnsavedPhoto()`, which does nothing after a successful save.
    - `save()` refuses while a photo is processing and passes `preparedPhoto` to `addLog`.
    - The service is built with the view model's injected photo store.
- `Views/AddWateringLog/AddWateringLogView.swift`:
  - Before: water, date and time, environment, error, help button.
  - After: a new **Photo** section.
    - States: Add Photo, "Preparing photo…" with Cancel, a thumbnail with Replace and Remove, and "This photo couldn't be added" with "Choose Another Photo".
    - Save is disabled while processing. Cancel discards the unsaved photo.
    - Swipe-to-dismiss is disabled while a photo is attached, including from the Help screen.
    - A full-screen preview is available.
- `Services/WateringLogService.swift`: `addLog(_:to:photo:)` and the ordering above. `deleteLog` deletes the file after the save.
- `Services/GrowService.swift`, `PlantService.swift`: collect photo IDs before the cascade delete, and delete the files after the save.
- `Views/PlantDashboard/WateringLogRowView.swift`:
  - Before: selection circle (no minimum size); a tappable content area whose accessibility label was only "Expand/Collapse log details" (hiding the values from VoiceOver); expanded detail rows.
  - After:
    - The circle has a 44 pt target and the Selected trait.
    - The collapsed row shows a photo symbol.
    - The summary is one VoiceOver element that reads "time, X added, Y retained, capacity Z%, has photo", with the Expanded/Collapsed value, a default action, and a "View photo" action.
    - Each detail row is one element.
    - The expanded row shows the thumbnail button, placed outside the collapse tap area.
- `Views/PlantDashboard/HistoryView.swift`: `viewerItem` state, `openPhoto(for:)`, the full-screen viewer, and a delete message that mentions the photo.
- `Views/Settings/SettingsView.swift`: a new **Storage** section showing "Photos: N · X MB" (read off the main actor), with a footer on local storage, backups and deletion.
- `App/EvapotrackApp.swift`: a `.task` that runs the launch cleanup.

---

## 8. Export

### 8.1 `Evapotrack/Services/DataExportService.swift` (modified in two steps)

- **Before:** `exportGrow(_:waterUnit:temperatureUnit:)` called `Date()` and `.formatted(date: .abbreviated, time: .shortened)` directly, which could not be tested. There were no tests.
- **Step 1 (`978971b`):** injectable `now:` and `formatDate:` parameters, defaulting to the old behavior. The output is unchanged. Snapshot tests pinned every line of the existing format.
- **Step 2 (`c5a1b67`):**
  - A plant whose logs have photos gets a **Photo** column (Yes/—). The Humidity column is padded when Photo follows it, and the divider widens by 10.
  - The export ends with "Photos: N watering log(s) have a photo. Photos stay on this device and are not included in this export."
  - A grow without photos exports byte for byte as before, and the step-1 snapshot test still passes unchanged.

The export remains English-only (LOC-3, pre-existing, not changed).

---

## 9. Accessibility and localization

| File | Before | After |
|---|---|---|
| `Assets.xcassets/evPrimaryBlue.colorset` | Light mode #4A90E2: 3.1:1 on the app background and 3.3:1 under white text | Light mode #2F6DBD: 4.9:1 and 5.2:1 (WCAG AA). Dark mode (#5DA3F5) unchanged. |
| `Assets.xcassets/evOnPrimary.colorset` (new) | — | Text color for blue fills: white in light mode, #0B1A2E in dark mode (white on the dark-mode blue was 2.6:1) |
| `AddWateringLogView` help button, `LimitExceededView` Close, `PlantFormView` Calculate | `.white` text on blue | `Color.evOnPrimary` |
| `GrowRowView`, `PlantRowView` | Selection circle about 24 pt, no selected trait | 44 pt frame (spacing reduced so the layout doesn't move) and the Selected trait |
| `HistoryView` trash button | No frame | 44 pt frame |
| `HistoryView` chart | Label only | Also an `AXChartDescriptor` (VoiceOver Audio Graph) |
| `HistoryView` add sheet | Shared the dashboard's `vm.isShowingAddWatering`, so both the dashboard and History tried to present the sheet | Its own `@State isShowingAddWatering` |
| `Utilities/Extensions.swift` | `shortFormatted`/`longFormatted`/`timeFormatted` used the device locale | Use `Strings.locale`: the app language plus the device region, e.g. es_US |
| `Models/UserSettings.swift` | — | `AppLanguage.locale` |
| `App/EvapotrackApp.swift` | — | `.environment(\.locale, settingsVM.settings.language.locale)` at the root, for DatePicker and formatted `Text` |
| `Views/CreateGrow/CreateGrowView.swift` | Inline `.formatted(...)` | `currentTime.longFormatted` |
| `Resources/InfoPlist.xcstrings` (new) and `project.pbxproj` knownRegions | Spanish not declared, so iOS ran the app in English and system UI stayed English on Spanish devices | en/es InfoPlist catalog and `es` in knownRegions |

---

## 10. Help text and strings

`Utilities/LocalizedStrings.swift` (+251/−…, EN and ES in every case):

- **Removed:**
  - `average` ("Average"), `noInsightsYet`, `retainedExceedsCapacity` (the old hard 105% error);
  - the fixed-unit `maxRetentionRange`, `waterAddedRange` and `temperatureRange` strings;
  - `expandLogDetails` and `collapseLogDetails`;
  - the help line "The more logs you record, the more accurate the recommendation becomes." (HELP-2: false for a recency-weighted estimate).
- **Added:**
  - recommendation texts (`expected`, `insightsNoHistory`, `insightsNoUsableData`, `basis…`, `note…`);
  - `editPlant`, `edit`, `editPlantLabel`, `editCapacityFooter`;
  - `saveAnyway`, `reviewValues`, `retainedOverCapacityTitle`/`Message`, `calculatorRunoffTooLarge`, `failedToLoadExampleData`;
  - `dataStoreErrorTitle`/`Message`;
  - the unit-aware range functions;
  - the photo strings (section, footer, add, replace, remove, choose another, preparing, failed, unavailable, view, hint, close, viewer label, storage, storage footer);
  - `expanded`/`collapsed`, `logRowAccessibility(...)`, `locale`.
- **Rewritten:**
  - `maxRetentionDescription`, `calculatorFooter`, and the goal description/range (5–50);
  - How To "What Is Max Retention Capacity?", "What Is Next?" and "Watering Protocol";
  - Create Plant (mentions Edit), Log Watering (mentions the photo), What Is Evapotrack (photos are local), and Download (photos not included; HELP-1 control names);
  - Grows and Plants (deletion includes photos);
  - the delete confirmations for grow, plant and log (the log message names its photo).

---

## 11. Website and privacy policy

Not live until merged. Publish when the photo release ships.

| Page | Before | After |
|---|---|---|
| `docs/index.html` | "iPhone, iPad & Android" card; About says "…for iPhone, iPad, and Android"; keywords include Android; "Monitor plant saturation levels…"; "interactive charts"; short alt text; footer #3E4A5C (≈1.9:1) | "iPhone & iPad… Android coming soon" (the existing "Coming Soon for Android" badge is kept); "See how much of your medium's Max Retention Capacity each watering refilled"; "charts with optional temperature and humidity overlays"; descriptive alt text; new "Watering Photos" card; canonical link; footer #8896AB |
| `docs/privacy-policy.html` | Dated March 22, 2026; "iOS and Android"; "SwiftData… and Android's Room database"; contact via "the support page listed on the App Store or Google Play" | Dated September 28, 2026; iPhone/iPad; new **Photos** section (picker, no library access, no GPS or camera data, not uploaded, not exported, deleted with the data or the app, no camera); device backups noted; contact by email and support page; new "This Website" section |
| `docs/support.html` | "…and Android devices running Android 8.0 (Oreo) or later"; data answers without photos | "An Android version is coming soon"; photos in the storage and uninstall answers; new FAQ "Does Evapotrack need access to my photos?" |
| `docs/watering-protocol.html` | A YouTube iframe loading on page view; five steps; tip about the reference table | Click-to-load poster → `youtube-nocookie.com`; new step "Aim for runoff every time" (goal %); "log what really happened"; a from-dry MRC measurement tip |
| `docs/reference.html` | "maximum volume… before runoff begins"; calculator tip without dry start | From-dry definition; "Start with dry medium… let it finish draining"; `scope="col"` on header cells |
| `docs/robots.txt`, `docs/sitemap.xml` | None | Allow all and the sitemap of the 5 public pages |

---

## 12. Internal documentation

- **Before:** `docs/Architecture.md`, `DataModel.md`, `NavigationMap.md`, `Requirements.md`, `Specification.md` and `video-watering-protocol-plan.md` were inside the GitHub Pages root, so they were publicly served. They were stale: they said iPad is portrait-only, example data has one plant, the example button is "disabled after loading", `save()` is private, entities are immutable, and Capacity % is capped at 105%.
- **After:** they moved to `engineering/app-docs/` and were corrected. Each now carries a note on the move.

The new `engineering/` folder (outside `docs/`, so not served on evapotrack.com, but visible in this public repository) holds:

- `reviews/`: the 2026-09-27 engineering review (HTML and Markdown).
- `research/algorithm/`: the simulation code, raw results and the final comparison table.
- `research/numeric-input/`, `research/export-snapshot/`: the reference models used to write the tests.
- `tools/`: the syntax checker and the HTML→Markdown converter.
- `revision-2/`: this change log and the implementation report.

---

## 13. Tests

| File | Status | What it covers |
|---|---|---|
| `InsightsAlgorithmTests.swift` | **deleted** (20 tests) | Tested the removed `computeNextWaterRecommendation` with fixtures that don't occur in practice (TEST-3) |
| `LegacyNextAlgorithmTests.swift` | new (19) | Characterizes the old algorithm through realistic histories, via `Support/LegacyRecommendationModel.swift`, so old and new behavior can be compared |
| `RecommendationEngineTests.swift` | new (30) | Classification, censoring, full runoff, drop limit, trend cap, goal clamp, MRC cap, 100 L cap, notes, ordering, non-finite input, determinism (SplitMix64) |
| `RecommendationSimulationTests.swift` | new (3) | Closed-loop checks: start at half the need → goal by the 7th watering; +6%/watering growth always gives runoff; a 35% drop recovers within 4 |
| `NumericInputTests.swift` | new (8) | en_US, es_ES, de_DE, fr_FR, pt_BR (and es_MX) vectors, grouping rules, rejections, round-trips |
| `ValidationTests.swift` | modified (64 → 69) | Messages in mL/L/gal and °C/°F |
| `MigrationTests.swift` | new (5), with `Support/PreV1Schema.swift` | Unversioned and versioned V1 stores open as V2 with every record; photo IDs persist across relaunch; an unknown older model still opens; V2 adds only `photoFileID` |
| `ModelTests.swift` | modified (13 → 15) | `photoFileID` defaults to nil and is kept |
| `PersistenceTests.swift` | new (9) | Failed save → rollback for every service; retry succeeds; example data shape and failure |
| `PlantFormViewModelTests.swift` | new (8) | Unrounded calculator value, typed override, runoff < water, goal rules, edit keeps exact values, edit doesn't touch logs, uniqueness, legacy goal |
| `AddWateringLogViewModelTests.swift` | new (5) | Comma decimals, unit messages, over-capacity confirmation, tolerance, error order |
| `WateringCalculationTests.swift` | modified (17) | Capacity % uncapped |
| `DataExportTests.swift` | new (3) | Snapshot before photos (unchanged after), snapshot with a photo, empty grow |
| `PhotoProcessorTests.swift` | new (9) | GPS/EXIF/TIFF removed (metadata and raw bytes), size limits, no upscaling, orientation, byte budget, fallback size, HEIC/JPEG naming, unreadable input |
| `PhotoStoreTests.swift` | new (10) | Commit, discard, delete, sweep, usage, file names |
| `PhotoLifecycleTests.swift` | new (15) | Add/delete/failed-save ordering for logs, plants and grows; launch cleanup; the form's photo flow |
| `Support/WateringHistory.swift`, `Support/TestImages.swift` | new | Test fixtures |

**Totals:** Before 152 tests. After 263. Passing: none confirmed, because none were run. Unverified: 263.

---

## 14. Project file

`EvapotrackDev.xcodeproj/project.pbxproj`: one line, `es` added to `knownRegions`. Signing, team, bundle ID, `MARKETING_VERSION` (1.0) and `CURRENT_PROJECT_VERSION` (1) were **not changed**. The file-system-synchronized groups pick up new files automatically.

## 15. Files not changed on purpose

- **Signing and version numbers.** Set these in Xcode for the release after checking App Store Connect (REL-1).
- **The 3-second launch screen (UX-1).** This is a product decision; the audit recommended shortening it.
- **`NavigationTests` writing to shared `UserDefaults` (TEST-4)**, the export's English-only text (LOC-3), and "gal" being US gallons (UNIT-2). These are listed as remaining issues in the implementation report.
