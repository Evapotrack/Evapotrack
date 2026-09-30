# EvapoTrack Next Revision: Final Engineering Report

**Date:** 2026-09-28
**Branch:** `claude/wonderful-edison-i0ukly` (14 commits on top of `89cc8c8`)
**Companion documents:**
- [`CHANGELOG-DETAILED.md`](CHANGELOG-DETAILED.md): file-by-file "before → after" for every change.
- [`../reviews/2026-09-27-engineering-review.md`](../reviews/2026-09-27-engineering-review.md): the audit this revision implements.
- [`../research/algorithm/README.md`](../research/algorithm/README.md): the simulation study behind the new algorithm.

> **Verification status.** Nothing in this revision has been compiled or run. The cloud environment has no Swift toolchain, and download.swift.org was blocked by the environment's network policy. Each Swift file passed a tree-sitter syntax parse. Expected test values were computed with Python reference models of the Swift code (kept in `engineering/research/`). Everything marked **UNVERIFIED — requires device/Xcode** must be checked before release.

### Verification levels used in these documents

| Level | Meaning | Reached so far |
|---|---|---|
| Implemented | The code or test exists on the branch | Everything listed |
| Syntax-checked | A tree-sitter parse accepted the file | Every Swift file |
| Compiled | Xcode built the app and the test target | **Not yet** |
| Unit-tested | The test was run and passed | **Not yet (0 of 268)** |
| Device-tested | Checked by hand on an iPhone or iPad | **Not yet** |
| Release-verified | Checked in an archived Release build or TestFlight | **Not yet** |

Descriptions of tests say what each test is **written to check**. None has been run, so none of them is evidence that the behavior works yet.

---

## 0. Audit findings: what existed, what was suggested, what was done

| ID | What existed | Suggested update | Status |
|---|---|---|---|
| ALG-1 | Next = (last retained + all-time mean) / 2 ÷ (1−goal); lags growing plants | Recency-weighted estimate | **Done**: damped-trend level (§2) |
| ALG-2 | Zero-runoff logs counted as exact demand | Treat as lower bound | **Done**: censored update |
| ALG-3 | Newest log at 100% runoff → all insights hidden | Skip it and explain | **Done**: skipped, with a note; `.noUsableData` state |
| ALG-4 | Goal 0.1–99.9% accepted | 5–50% | **Done**: form 5–50; the engine clamps legacy values and shows a note |
| ALG-5 | One outlier or top-up moved Next by half | Robustness | **Done**: 25% maximum drop per watering, trend cap ±25% |
| ALG-6 | Interval ignored | Consider time-aware model | **Declined, with evidence**: rate × elapsed (candidate G) failed scenario S8b (water-when-dry) |
| MRC-1 | Three definitions; example data 1.6/2.1 L | One from-dry definition | **Done**: app, help, site, example data 1.5/2.3 L |
| MRC-2 | MRC immutable, and the hard 105% block | Edit Plant, confirm instead of block | **Done** |
| MRC-3 | Calculator stored the rounded display value | Keep unrounded | **Done** |
| LOC-1 | `Double(text)` rejected "1,5" | Locale-aware parser | **Done**: `NumericInput` |
| LOC-2 | Spanish not declared; device-locale dates | Declare es; app-language dates | **Done** |
| LOC-3 | Export English-only | Optional | Not done (P3) |
| UNIT-1 | Limits always shown in L and °C | Show user units | **Done** |
| UNIT-2 | "gal" is US only | Optional | Not done (P3) |
| DATA-1 | No versioned schema | VersionedSchema + plan + test | **Done** |
| DATA-2 | No rollback after a failed save | Roll back | **Done** |
| DATA-3 | No import/restore | Consider | Not done (future) |
| DATA-4 | Example data `try? save()` | Report errors | **Done** |
| A11Y-1 | Row label hid values from VoiceOver | Restructure | **Done** |
| A11Y-2 | Light blue 3.0:1; white on dark blue 2.6:1 | Darker blue; on-primary color | **Done** |
| A11Y-3 | Targets under 44 pt | 44 pt | **Done** for row circles and the History trash button |
| A11Y-4 | No chart descriptor | Optional | **Done** |
| UX-1 | 3 s launch screen every launch | Shorten | **Not done**: product decision left to the owner (P2) |
| UX-2 | Two sheets on one binding | Separate state | **Done** |
| UX-3 | Small friction points | Optional | Not done (P3) |
| WEB-1…6 | Android claims, "saturation", YouTube tracking, protocol gaps, public internal docs, SEO | Corrections | **Done** (§7) |
| PRIV-1 | Policy silent on photos | Describe local photos | **Done**: publish with the release |
| TEST-1…3 | No VM/service/export/migration tests; misleading algorithm tests | Add tests | **Done**: 152 → 268 |
| TEST-4 | NavigationTests use shared UserDefaults | Isolate | **Done**: private suite per test; SettingsViewModel takes an injectable store |
| EXP-1 | Export untested | Snapshot first | **Done**, committed before the format change |
| PERF-1 | Image work must be off the main actor | nonisolated processing | **Done** |
| PERF-2 | HistoryView regroups on every body; Catmull-Rom overshoot | Optional | Not done (P3) |
| DEBT-1 | Algorithm split across layers; duplicated parsing | Consolidate | **Done** |
| DEBT-2 | Dead code, duplicated overlays | Optional | Partly (stale strings removed) |
| HELP-1 | Download help named wrong controls | Fix | **Done** |
| HELP-2 | "More logs, more accurate" | Remove | **Done** |
| REL-1 | Version 1.0 (1) | Verify against App Store Connect | **Not changed on purpose**: verify there |
| REL-2 | Warnings baseline unknown | Check | UNVERIFIED — requires Xcode |
| REL-3 | Target named EvapotrackDev | Optional | Not changed |
| SET-1 | Reset has no confirmation; export result ignored | Optional | Not done (P3) |

---

## 1. What changed

A file-by-file summary follows. Full before/after detail is in `CHANGELOG-DETAILED.md`.

**App: new files**
- `Services/RecommendationEngine.swift`: pure Next engine.
- `Utilities/RecommendationText.swift`: explanation sentences.
- `Utilities/NumericInput.swift`: locale-aware parser.
- `Models/SchemaV1.swift` (frozen), `Models/Schema.swift`: V2, migration plan.
- `Services/PersistenceController.swift`: store opening with fallback.
- `Views/Components/DataStoreErrorView.swift`.
- `Services/ExampleDataService.swift`.
- `ViewModels/PlantFormViewModel.swift` and `Views/PlantForm/PlantFormView.swift`: Add/Edit Plant, replacing the CreatePlant pair.
- `Services/Photos/*` (PhotoStore, PhotoProcessor, PickedImageFile, PhotoImageLoader, PhotoMaintenance).
- `Views/Photos/*` (PhotoViewer with ZoomableImageView, WateringPhotoThumbnail).
- `Resources/InfoPlist.xcstrings`, `Assets.xcassets/evOnPrimary.colorset`.

**App: modified files**
- `AppConstants`: goal range, confirmation factor, photo sizes, nonisolated.
- `EvapotrackApp`: explicit container, error screen, photo cleanup, locale.
- `Grow`/`Plant`/`WateringLog`: moved under SchemaV2; `photoFileID`.
- `UserSettings`: `AppLanguage.locale`.
- `WateringCalculationService`: algorithm removed; Capacity % uncapped.
- `ValidationService`, `DisplayFormatter`: limits in user units.
- `UnitConversionService`, `Logger`: nonisolated; photos logger.
- `ServiceError`: `saveOrRollback`.
- `Grow/Plant/WateringLogService`: rollback, photo ordering, `updatePlant`.
- `DataExportService`: injectable date; Photo column and note.
- `PlantDashboardViewModel`: `recommendation` outcome.
- `AddWateringLogViewModel`: parser, over-capacity confirmation, photo state.
- `InsightsPanelView`: Expected/Next/Goal and explanations.
- `PlantDashboardView`: Edit button.
- `HistoryView`: photo viewer, own add sheet, chart descriptor, 44 pt trash.
- `HistoryPanelView`: parameter removed.
- `WateringLogRowView`: accessibility restructure, photo indicator and thumbnail.
- `AddWateringLogView`: photo section, confirmation alert.
- `SettingsView`: Storage row.
- `GrowListView`: example data via the service, with an error message.
- `GrowRowView`/`PlantRowView`: 44 pt circles.
- `LimitExceededView`: on-primary text.
- `CreateGrowView`: shared date helper.
- `PlantListView`: uses PlantFormView.
- `Extensions`: app-language dates.
- `LocalizedStrings`: see changelog §10.
- `evPrimaryBlue`: #2F6DBD in light mode.
- `project.pbxproj`: `es` region.

**Tests:** 11 new test files, 4 support files, 4 modified, 1 deleted (§6).

**Website:** index, privacy policy, support, watering protocol and reference corrected; robots.txt and sitemap.xml added; internal docs moved to `engineering/app-docs/` (§7).

---

## 2. Algorithm

### Old model
```
expected = (retained_last + mean(retained_all)) / 2
next     = min(expected, MRC) / (1 − goal)        # returns nil when retained_last ≤ 0
```
- Every log counted equally, forever. After 20 waterings, a plant whose demand doubles moves the all-time mean by only about 1/20 per watering.
- A zero-runoff log (retained = water added) was averaged in as if it were the true demand. Because Next then under-waters, the next watering also gets no runoff: the **zero-runoff spiral** (38–96% of waterings without runoff in growth scenarios).
- A 100% runoff log made `retained_last = 0`, so Insights showed nothing at all.

### New model (`RecommendationEngine`)
It estimates **D**, the volume the medium absorbs before free drainage starts, from the grower's own measurements:
- **Runoff > 0:** retained = D exactly (less measurement error). These waterings update a Holt level with a damped trend (α 0.5, β 0.2, φ 0.8). The trend follows sustained growth or decline; the damping stops a few noisy points from extrapolating forever.
- **Runoff = 0:** retained = W ≤ D, which is a **censored** observation (a lower bound). If W exceeds the current forecast, the estimate rises to W and the trend is not allowed to be negative. Otherwise the watering carries no new information and is ignored.
- **Runoff = 100%:** no information about D, so it is skipped with a note.
- **Robustness:** the effective observation is floored at 75% of the forecast, so one top-up or odd watering lowers the estimate by at most a quarter. The trend is capped at ±25% of the level.
- **Safety bounds:** estimate ≤ MRC; goal clamped to 5–50%; Next ≤ 100 L. Every bound that applies adds a visible note.
- **Output:** Next = estimate ÷ (1 − goal), goal runoff = Next × goal, plus the basis ("based on recent retained water of X and a 15% goal", or "none of your waterings has produced runoff yet, so the plant needs at least X") and notes.

### Why this model
The candidates were compared in a closed loop: the simulated grower follows Next, and runoff is a function of the true, changing D. The scenarios covered 18 conditions (constant, bad first watering, growth of 3/6/10%, decline, sudden drop, noise ±20/30%, irregular intervals, top-ups, generous waterings, long gaps, step change, realistic grow cycles). Each candidate × scenario was run with 200 seeds.

The study ran in four rounds (`study.py`, `round2.py`–`round4.py`). The candidate families were:
- **A:** the current model, alone and with a censoring layer.
- **B:** latest watering only.
- **C:** EWMA with α 0.3/0.5/0.7, with and without censoring and a clip on downward moves.
- **D:** recency-weighted windows and medians of the last 3–7 waterings.
- **E:** Holt level plus damped trend, with censoring.
- **F:** runoff-feedback controllers.
- **G:** time-aware rate × elapsed hours.

The winner was **E with censoring, a 25% maximum drop per watering and a ±25% trend cap** (α 0.5, β 0.2, φ 0.8). The closest rival was EWMA with α 0.6 and a 25% clip (round 4, `round4_output.txt`). It matched E on stable plants and recovered faster after a sudden 35% drop (4 vs 6 waterings). E was chosen because it follows sustained change better: 0.3% vs 2.5% zero-runoff waterings at +6%/watering growth, 12.0% vs 20.6% at +10%, 4.6 vs 6.5 pp error in decline, and better averages overall (7.1% zero runoff and 5.9 pp error, vs 8.4% and 6.4 pp). **G was rejected:** it fails when growers water when the pot is dry at irregular intervals (S8b), and the timing data doesn't justify the extra complexity. **F** reacted to noise in the runoff reading.

**Results, current vs shipped (averages over 18 scenarios; the full table is in `research/algorithm/final_table_output.txt`):**

| Metric | Current | Shipped |
|---|---|---|
| Mean distance from goal runoff (pp) | 9.9 | **6.2** |
| Median distance (pp) | 10.2 | **5.4** |
| Waterings with zero runoff | 34.4% | **9.7%** |
| Waterings above 2× goal runoff | 7.2% | **4.5%** |
| More than 5 pp under the goal | 50.3% | **27.8%** |
| Waterings to converge (bad start / 35% drop / step) | 14 / 30 / 30 | **5 / 6 / 5** |
| Top-up sensitivity (S9, pp added) | +10.3 | **+3.7** |

**Honest trade-offs:** under stationary noise of ±20–30% (S7, S7b) and irregular 1–3 day intervals (S8), the shipped engine has more waterings above 2× goal (10.3% vs 6.3%, 21.0% vs 14.9%, 39.0% vs 22.6%). That is the cost of reacting to real change. S8 is also bad for the old model (49.7% zero runoff). A stable, constant plant (S1) performs the same under both (2.4 vs 2.5 pp).

**Test results:** 30 engine unit tests, 3 closed-loop simulation tests, and 19 characterization tests of the old model. All of them are UNVERIFIED — requires device/Xcode (not run). The expected values came from `research/algorithm/engine_ref.py` and `expectations.py`.

---

## 3. Max Retention Capacity

**Final definition:** *the most water the medium takes in during one watering, starting from dry medium, before runoff begins.* Measure it by watering dry medium slowly until runoff appears, letting it finish draining, and subtracting the runoff from the water added.

**Places made consistent:**
- The Add/Edit Plant field description, calculator footer and edit footer (EN/ES).
- How To › "What Is Max Retention Capacity?", "Watering Protocol" and "What Is Next?" (Next never assumes more than MRC).
- The over-capacity confirmation text.
- The recommendation note "Limited by this plant's Max Retention Capacity…".
- The example data (1.5 L soil and 2.3 L coco, matching the reference table).
- `docs/reference.html` intro and tip, and the `docs/watering-protocol.html` tip.
- The internal Specification and Requirements.

**MRC is not the amount to give every time.** MRC is a property of the pot and medium: the most they can take in from dry. Next is a demand estimate: what this plant has recently been retaining. Next is normally below MRC, and MRC only acts as a ceiling on the estimate. Changing MRC doesn't change Next unless the estimate was at or above the old or new capacity. A test checks this (`test_editingCapacity_onlyMattersWhenItIsTheLimit`), and the How To now says it in the app.

**Behavior:**
- MRC is editable (Edit Plant).
- Calculator results are stored unrounded.
- Capacity % is uncapped, so values above 100% signal a capacity that is set too low.
- Retaining more than 105% of MRC asks for confirmation instead of blocking.
- MRC caps the estimate, not the logged data.

---

## 4. Photos

- **Picker:** SwiftUI `PhotosPicker` limited to images. The picked item is received as a file through `FileRepresentation`, so large originals are not loaded into memory. A newer pick replaces an older one, and stale results are discarded.
- **Permissions:** none. The picker runs out of process and shares only the chosen photo. There is no usage description, no `PHPhotoLibrary`, and no camera, AVFoundation or `UIImagePickerController`. The privacy manifest is unchanged: no data is collected, and no new required-reason API is used (the cleanup compares file names with database IDs and reads only file sizes).
- **Storage:** `Application Support/WateringPhotos/<uuid>.heic` + `<uuid>_thumb.heic` (`.jpg` if HEIC encoding is unavailable). The database stores only `photoFileID`. Photos are included in the user's device backups; the `.incoming` working folder is excluded. Nothing is uploaded.
- **Compression:** ImageIO downsampling (the full-size bitmap is never decoded). The detail image is ≤ 2048 px long edge, at HEIC 0.70, falling back to 0.55 and then 1600 px to stay ≤ 1.5 MB (expected about 0.3–0.5 MB). The thumbnail is ≤ 360 px, made from the detail image. Everything runs in `Task.detached`.
- **Metadata:** orientation is baked into the pixels. No metadata dictionary is written, so EXIF, GPS, TIFF make/model and maker notes are dropped. This is tested with a GPS-tagged fixture, checking both the parsed metadata and the raw bytes.
- **UI:**
  - The Add Watering "Photo" section: add, preparing with cancel, thumbnail with replace/remove, failure message. Save waits for processing; Cancel discards the photo; swipe-dismiss is off while one is attached.
  - History: a photo symbol on the collapsed row, and the thumbnail in the expanded row.
  - The full-screen viewer: pinch zoom to 4×, double-tap zoom, pan, close by X, swipe down or VoiceOver escape. Reduce Motion is respected.
  - Settings: "Photos: N · X MB".
- **Deletion:** a log, plant or grow deletion is saved first, then the files are deleted. A failed save keeps them. The launch cleanup removes orphans left by a crash, and "Photo unavailable" covers files missing for any other reason.
- **Migration:** `photoFileID` is the only schema change (V1 → V2, lightweight, nil for existing logs).
- **Export:** a Photo column (Yes/—) for plants that have photos, and a closing note that photos stay on the device. Exports without photos are unchanged.

---

## 5. Data migration (V1 → V2)

- `SchemaV1` (1.0.0) is a frozen copy of the shipped models. The model files were last changed on 2026-03-21, before the first App Store upload.
- `SchemaV2` (2.0.0) adds `WateringLog.photoFileID: UUID? = nil`. That is the only difference, and a test asserts it.
- `EvapotrackMigrationPlan`: one lightweight stage, V1 → V2.
- `PersistenceController.makeContainer()` opens the store with the plan. If that throws, for example for a store created by an unversioned build, it logs the error and retries with automatic migration against the current schema. If both fail, the app shows `DataStoreErrorView` and never replaces the store with an empty one.
- Tests cover: an unversioned V1 store, a versioned V1 store, photo IDs across relaunch, a store from an unknown older model (`Support/PreV1Schema.swift`), and the V1/V2 field difference.
- **UNVERIFIED — requires device/Xcode:** install the App Store build, create data, then install this build over it and confirm every grow, plant and log is intact.

---

## 6. Tests

```text
Before: 152 tests
After: 268 tests
Passing: 0 confirmed (no test was run: no Swift toolchain in this environment)
Unverified: 268 (one will be skipped until a store from the App Store build is added; see EvapotrackDevTests/Fixtures/README.md)
```

New: RecommendationEngineTests 34, LegacyNextAlgorithmTests 19, RecommendationSimulationTests 3, NumericInputTests 8, MigrationTests 6, PersistenceTests 9, PlantFormViewModelTests 8, AddWateringLogViewModelTests 5, DataExportTests 3, PhotoProcessorTests 9, PhotoStoreTests 10, PhotoLifecycleTests 15.
Modified: ValidationTests 64 → 69, ModelTests 13 → 15, WateringCalculationTests 17 (capacity no longer capped).
Deleted: InsightsAlgorithmTests 20 (tested the removed function).

Unchanged: UnitConversionTests 30. NavigationTests 8 (now isolated in a private UserDefaults suite, TEST-4).

Run with **Product › Test** in Xcode (scheme EvapotrackDev) on an iOS 17+ simulator. Expect to fix small compile-level issues first, because the code has never been built.

---

## 7. Website

The pages are not live until merged. Publish them together with the App Store release that contains photos.

1. Removed the claims of current Android support (feature card, About, keywords, privacy policy Room wording, support FAQ). The "Coming Soon for Android" badge is kept.
2. "Monitor plant saturation levels" → "See how much of your medium's Max Retention Capacity each watering refilled".
3. "Interactive charts" → "charts with optional temperature and humidity overlays".
4. Watering Protocol: YouTube is no longer loaded on page view; a click-to-play poster loads `youtube-nocookie.com`.
5. Watering Protocol: new step "Aim for runoff every time" (goal %, 15% default), "log what really happened", and the from-dry MRC tip.
6. Reference: from-dry MRC definition and calculator instructions; `scope="col"` on table headers.
7. Privacy policy: new Photos section, device-backup note, email/support contact, "This Website" section, iPhone/iPad only, date September 28, 2026.
8. Support: photo FAQ; photos in the storage and uninstall answers; Android marked coming soon.
9. Home: "Watering Photos" feature card; descriptive screenshot alt text.
10. All pages: canonical links; footer copyright contrast #3E4A5C → #8896AB. New robots.txt and sitemap.xml.
11. Internal engineering docs moved out of the published `docs/` folder into `engineering/app-docs/` and corrected.

---

## 8. Remaining issues

**P0:** none known. Because the code has not been compiled, a failed build is itself the first thing to rule out.

**P1**
- **Build and run the test suite.** 268 tests and all new code have never been compiled.
- **Upgrade test.** Verify V1 → V2 on a device with real App Store data before release.
- **REL-1.** Set `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` above the live App Store version in Xcode. They are unchanged here (1.0 / 1) on purpose.

**P2**
- UX-1: the 3-second launch screen on every launch. The audit recommends shortening it or showing it once; this was left to you.
- Publish the website and privacy policy changes only when the photo release is live.
- If the new blue (#2F6DBD) changes the brand look, confirm it; it could also be applied to App Store screenshots.

**P3**
- LOC-3: export text is English-only.
- UNIT-2: "gal" is the US gallon.
- SET-1: Reset has no confirmation.
- PERF-2: HistoryView regrouping and Catmull-Rom overshoot.
- DEBT-2: leftover dead code (`Strings.theme`, `overlayAxisColor`, `Date.daysBetween`).
- REL-3: the target is named EvapotrackDev.
- UX-3: small friction points.
- No JSON-LD block on the home page (optional WEB-6 item).

**Future ideas:** import/restore from export (DATA-3); per-plant photo gallery or timeline; showing the explanation's inputs in History; a String Catalog migration (it would replace the in-app language switch); Android parity.

---

## 9. Device verification still required

All items below are **UNVERIFIED — requires device/Xcode**.

**Build and tests**
1. The project builds with no errors, on the iOS 17 minimum and on the latest SDK; review the warnings (REL-2).
2. All 268 tests pass on a simulator; fix and re-run any failures. Capture a store from the App Store build (EvapotrackDevTests/Fixtures/README.md) so the real-store migration test runs instead of being skipped.

**Data**

3. Upgrade from the App Store build keeps all data (V1 → V2), including after a relaunch.
4. `DataStoreErrorView` appears if the store is unreadable (simulate with a corrupted store file on a simulator).
5. The example data loads with two plants and six logs each; Capacity % is 45–87% for soil and 50–63% for coco.

**Recommendation and input**

6. The Insights panel shows Expected/Next/Goal and explanation lines in EN and ES, for: no logs, all 100% runoff, zero runoff, rising and falling demand, and capacity-limited.
7. Comma decimals work with the device region set to Spain, Germany, France and Brazil (typing "1,5" on the decimal pad), and limits show in mL/L/gal and °C/°F.

**Plants and over-capacity logs**

8. Edit Plant saves every field; logs are unchanged; Capacity % and Next update.
9. The over-capacity alert: Save Anyway saves, Review returns to the form.

**Photos**

10. Pick HEIC, JPEG, PNG, a Live Photo, a screenshot, a 48 MP and a ProRAW photo, and a shared-album photo. Each is prepared in about 1 s. The saved size is under 1.5 MB, and there is no memory spike.
11. A saved photo has no GPS: export the file from the simulator container and inspect it with `mdls` or exiftool.
12. The viewer: pinch, double-tap, pan, swipe down to close, the X button, VoiceOver escape, rotation on iPad, and Reduce Motion (no slide animation).
13. Cancel, Replace and Remove leave no files behind. Force-quit between picking and saving, relaunch, and confirm the orphan is removed.
14. Deleting a log, plant and grow removes its photo files; "Photo unavailable" appears if a file is removed manually.
15. The Settings Storage row matches the actual files; the export shows the Photo column and note.
16. There is no Photos permission prompt at any point.

**Accessibility and localization**

17. VoiceOver in History reads the values, expanded state and "View photo" action; the chart Audio Graph works.
18. Tap targets are 44 pt (Accessibility Inspector); the new blue looks right in light mode; buttons on blue are readable in dark mode.
19. A Spanish device shows Spanish system UI (photo picker, share sheet, date picker); the in-app Spanish setting shows Spanish month names; `es.lproj/InfoPlist.strings` is in the built app.
20. Dynamic Type at accessibility sizes: the photo section, Replace/Remove layout, and rows.
21. The History "+" presents one sheet only (UX-2).

**Release**

22. Version and build numbers are set above App Store Connect's (REL-1). Signing is unchanged.
23. The website renders on a phone, the protocol video plays after the click, and the privacy policy is published with the release.
