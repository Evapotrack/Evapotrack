# Evapotrack - Technical Specification

> Internal document. Moved out of the public website folder (`docs/`) on 2026-09-28 and updated for the next revision (recommendation engine, Edit Plant, schema V2, watering photos).

## Architecture

MVVM (Model-View-ViewModel) with service layer, targeting iOS 17+ using SwiftUI and SwiftData.

## Technology Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | SwiftUI (iOS 17+) |
| Persistence | SwiftData (@Model) |
| Settings | UserDefaults (JSON-encoded) |
| State Management | @Observable, @Environment |
| Navigation | NavigationStack + typed navigationDestination |
| Haptics | UIImpactFeedbackGenerator / UINotificationFeedbackGenerator |
| Logging | OSLog (Logger) |

## Key Design Decisions

### Editing
Grows and watering logs are immutable after creation (create or delete only). Plants can be edited (name, pot size, medium, Max Retention Capacity, goal runoff %) from the dashboard; editing a plant never changes its logs. Retained volumes stay as measured, and Capacity % and Next recalculate from the new values.

### Internal Units
All numeric values are stored in internal units (liters for volume, Celsius for temperature). Display units (mL/L/gal, C/F) are applied at render time via UnitConversionService and DisplayFormatter. Stored values are never rounded.

### Single NavigationStack
GrowListView owns the sole NavigationStack. Child views (PlantListView, PlantDashboardView) are pushed into it. This prevents navigation stack conflicts and follows Apple's recommended pattern.

### Typed Navigation IDs
GrowNavID and PlantNavID wrapper structs prevent UUID collision in navigationDestination registrations, since both Grow and Plant use UUID identifiers.

### Service Layer
Services (GrowService, PlantService, WateringLogService) encapsulate SwiftData CRUD operations. All services are @MainActor and accept ModelContext via init (plus an optional PhotoStore and an injectable save handler for tests). Every save goes through `ModelContext.saveOrRollback`, which rolls the context back and rethrows if the save fails, so nothing half-done stays in memory.

### Configure Pattern
ViewModels use a `configure(modelContext:)` method called from `.onAppear` rather than accepting ModelContext in init. This works around SwiftUI's @State initialization timing constraints.

## Validation Rules

| Field | Rule | Constant |
|-------|------|----------|
| Total grows | Max 30 | maxGrowCount |
| Plants per grow | Max 25 | maxPlantsPerGrow |
| Total plants | Max 750 (across all grows) | maxTotalPlants |
| Grow name | 1-50 chars, not blank, unique (case-insensitive) | maxGrowNameLength |
| Plant name | 1-50 chars, not blank, unique within grow | maxPlantNameLength |
| Pot size | Not blank | - |
| Medium type | Not blank | - |
| Max retention | 0.001-100 liters (messages shown in the user's unit) | maxRetentionCapacityRange |
| Water added | 0.001-100 liters (messages shown in the user's unit) | waterAddedRange |
| Runoff | >= 0 and <= water added | - |
| Retained | Above 105% of max retention capacity asks for confirmation (never rejected) | retainedConfirmationFactor |
| Temperature | -50 to 60 C (optional) | - |
| Humidity | 0-100% (optional) | humidityRange |
| Date/time | Not in the future, unique per plant (to the minute) | - |
| Goal runoff % | 5-50 when entered (optional, defaults to 15%); older out-of-range values are kept but clamped when used | goalRunoffPercentRange |
| Numbers | Parsed with the device region's decimal separator ("1,5" and "1.5") | NumericInput |

## Algorithm: Next Water Recommendation

Implemented by the pure `RecommendationEngine` (Services/RecommendationEngine.swift). It estimates how much the plant will retain before runoff starts, then sizes Next to reach the goal runoff:

1. Waterings are sorted by date. Each is classified: measured (0 < runoff < water), no runoff, full runoff (100%), or invalid.
2. Measured waterings update a Holt level with a damped trend (alpha 0.5, beta 0.2, phi 0.8). The trend is capped at ±25% of the level, and one watering can lower the forecast by at most 25%, so a small top-up doesn't throw it off.
3. A no-runoff watering is a lower bound (the plant needed at least that much). It raises the estimate only if it is above the forecast. A full-runoff watering carries no retention information and is skipped.
4. The estimate is capped at Max Retention Capacity. `next = estimate / (1 - goal%)`, with the goal clamped to 5-50% and Next capped at 100 L.
5. Outcomes are no history, no usable data (every watering drained completely), or a recommendation with its basis and notes (no runoff raised, full runoff skipped, demand rising or falling, limited by capacity, goal adjusted, limited by maximum). The notes are shown under Insights in the user's units.

Selection evidence (18 simulated scenarios, candidates A-F) is in `engineering/research/algorithm/`.

## Interval Recalculation

When logs are added or deleted, WateringCalculationService.recalculateIntervalHours sorts all logs chronologically and computes hours between consecutive entries. The first log gets nil interval.

## Entity Limits & Enforcement

Counters are displayed in list section headers (e.g., "2/30" for grows, "5/25" for plants). When a user taps + and a limit is reached, a LimitExceededView modal is shown instead of opening the creation form. The modal explains the constraint and has a Close button.

| Limit | Value | Enforcement |
|-------|-------|-------------|
| Grows | 30 | GrowListView + button shows modal |
| Plants per grow | 25 | PlantListView + button shows modal |
| Total plants | 750 | PlantListView checks fetchCount before opening form |

## Data Export

SettingsView accepts an optional `Grow` parameter. When opened from PlantListView (with a grow), a "Download Data" section appears for that grow. When opened from GrowListView (no grow), the export section is hidden. DataExportService generates a plain-text report containing grow metadata, all plants, and their watering log history in a tabular format. Temp/Humidity columns appear dynamically if any log has that data. A Photo column (Yes/—) appears for plants with photos, and the export ends with a note that photos are not included. Photo-less exports are unchanged (pinned by DataExportTests). Values are formatted in the user's display units. The export file is saved as `.txt` via `.fileExporter`.

## Retained Water Chart

HistoryView includes a toggleable Swift Charts line chart showing retained water volumes across all logs for a plant. The chart button toggles between chart view and log list — only one is visible at a time. The chart plots all logs but limits dots to 10 evenly spaced points and shows only the oldest and most recent date labels to prevent overcrowding. Chart data points use the same unit conversion as the rest of the display. The chart has an accessibility label summarizing the data point count and an AXChartDescriptor for VoiceOver Audio Graphs.

## Example Data Loader

GrowListView shows a "Try Example Data" button in the empty state (when no grows exist). Tapping it runs ExampleDataService, which creates a sample grow with two plants (1 gal soil, MRC 1.5 L; 1 gal coco, MRC 2.3 L) and six watering logs each, including temperature and humidity, saved in one step. The button is part of the empty state, so it disappears once a grow exists. If saving fails, nothing is kept and an error is shown. This helps first-time users explore the app's features before entering their own data.

## Accessibility

- VoiceOver: all interactive elements have accessibilityLabel; decorative images hidden; modal traits on overlays
- Dynamic Type: semantic fonts used throughout; padding scaled for larger text sizes
- Color contrast: custom palette maintains readability in both light and dark modes
- Touch targets: minimum 44x44pt on toolbar buttons and row selection circles
- History rows: the summary is read as one element with its values and expanded state, and "View photo" is an accessibility action

## Device & Orientation

- **Orientation**: iPhone portrait; iPad all four orientations
- **Device family**: iPhone and iPad (TARGETED_DEVICE_FAMILY = "1,2")
- **Deployment target**: iOS 17.0
- **Export compliance**: ITSAppUsesNonExemptEncryption = NO (no encryption used)

## iPad Adaptive Layout

The app uses the same stacked navigation flow on iPad as iPhone. `@Environment(\.horizontalSizeClass)` detects iPad (`.regular`) and applies targeted adjustments:

- **Modal overlays** (DeleteConfirmationView, LimitExceededView): capped at 420pt width on iPad
- **Summary grid**: 3 columns on iPad (vs 2 on iPhone) for the 4 metric cells
- **Plant info HStack**: constrained to 500pt max width, centered
- **Retained water chart**: 260pt height on iPad (vs 180pt on iPhone)
- **Lists and forms**: `.insetGrouped` style auto-adapts content width on iPad — no manual constraint needed

## Privacy

- No tracking (NSPrivacyTracking = false)
- No data collection (NSPrivacyCollectedDataTypes empty)
- Only required-reason API accessed: UserDefaults (reason CA92.1). Photo cleanup compares file names with database IDs and reads file sizes only (no file-timestamp or disk-space APIs).
- All data stored locally on device; nothing sent to the internet
- Photos: chosen with PhotosPicker (out of process, no permission); stored copies have no EXIF/GPS

## Watering Photos

One optional photo per watering log. PhotoProcessor (ImageIO) downsamples to 2048 px (thumbnail 360 px), bakes in orientation, and writes HEIC (JPEG fallback) with no metadata, keeping the detail image under about 1.5 MB. PhotoStore keeps files in Application Support/WateringPhotos/<uuid>.heic and <uuid>_thumb.heic. The model stores only `photoFileID`. The ordering is crash-safe: copy the photo then save the log, and save a deletion then delete the files. A launch sweep removes files no log refers to. The viewer is a full-screen cover with pinch or double-tap zoom, closed with the X button, a swipe down, or VoiceOver escape.

## Persistence and Migration

The store is opened through `PersistenceController` with a versioned schema. SchemaV1 is frozen, matching the shipped model. SchemaV2 adds `WateringLog.photoFileID`, and a lightweight migration stage connects them. If the staged plan fails, it retries with automatic migration. If the store cannot be opened, DataStoreErrorView explains what happened instead of starting empty.

## v2 Roadmap

Features planned for future updates:

- **App Icon**: Professional 1024x1024px icon for App Store. Design should reflect watering/plant theme using app's blue palette.
- ~~**Photos**~~: Implemented per watering log (see Watering Photos)
- **Onboarding Flow**: 3-4 swipeable pages on first launch covering core concepts (create grow, add plant, log watering, recommendations). Show once via UserDefaults flag.
- ~~**Localization**~~: Completed in Phase 6 — EN/ES in-app switching via custom `Strings` enum
