# Evapotrack - Technical Specification

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

### Immutability
All entities (Grow, Plant, WateringLog) are immutable after creation. Users can create or delete, but never edit. This simplifies state management and eliminates update conflict scenarios.

### Internal Units
All numeric values are stored in internal units (liters for volume, Celsius for temperature). Display units (mL/L/gal, C/F) are applied at render time via UnitConversionService and DisplayFormatter. Stored values are never rounded.

### Single NavigationStack
GrowListView owns the sole NavigationStack. Child views (PlantListView, PlantDashboardView) are pushed into it. This prevents navigation stack conflicts and follows Apple's recommended pattern.

### Typed Navigation IDs
GrowNavID and PlantNavID wrapper structs prevent UUID collision in navigationDestination registrations, since both Grow and Plant use UUID identifiers.

### Service Layer
Services (GrowService, PlantService, WateringLogService) encapsulate SwiftData CRUD operations. All services are @MainActor and accept ModelContext via init. The save() method is private to prevent external callers from bypassing business logic.

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
| Max retention | 0.001-100 liters | maxRetentionCapacityRange |
| Water added | 0.001-100 liters | waterAddedRange |
| Runoff | >= 0 and < water added | - |
| Retained | <= 105% of max retention capacity | maxRetainedFactor |
| Temperature | -50 to 60 C (optional) | - |
| Humidity | 0-100% (optional) | humidityRange |
| Date/time | Not in the future, unique per plant (to the minute) | - |
| Goal runoff % | 0.1-99.9 (optional, defaults to 15%) | targetRunoffPercent |

## Algorithm: Next Water Recommendation

1. If < 3 logs: formula-only estimate based on retention capacity and goal runoff %.
2. If >= 3 logs: blend formula estimate (40%) with history-based average (60%).
3. Formula: `capacity / retentionFactor` where `retentionFactor = 1 - goalRunoff/100`.
4. History: weighted moving average of past watering volumes.
5. Goal runoff amount: `next * goalRunoffPercent / 100`.

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

SettingsView accepts an optional `Grow` parameter. When opened from PlantListView (with a grow), a "Download Data" section appears for that grow. When opened from GrowListView (no grow), the export section is hidden. DataExportService generates a plain-text report containing grow metadata, all plants, and their watering log history in a tabular format. Temp/Humidity columns appear dynamically if any log has that data. Values are formatted in the user's display units. The export file is saved as `.txt` via `.fileExporter`.

## Status Badges

PlantRowView displays a StatusBadgeView capsule showing the plant's watering status. Status is computed from the most recent log's date and the average interval between waterings:

| Status | Condition | Color |
|--------|-----------|-------|
| New | No logs exist | evSlateGray |
| Healthy | Within recommended interval | RGB(0.2, 0.65, 0.3) |
| Due Soon | Within 1 day of recommended interval | RGB(0.85, 0.55, 0.1) |
| Due Today | At the recommended interval | RGB(0.85, 0.55, 0.1) |
| Overdue | Past the recommended interval | RGB(0.85, 0.2, 0.2) |

Badge colors are fixed RGB values (not system adaptive) to ensure white text contrast in both light and dark modes.

## Retained Water Chart

HistoryView includes a toggleable Swift Charts line chart showing retained water volumes across all logs for a plant. The chart is hidden by default and toggled via a "Show Chart" / "Hide Chart" button. Chart data points use the same unit conversion as the rest of the display. The chart has an accessibility label summarizing the data point count.

## Example Data Loader

SettingsView includes a "Load Example Data" button (visible only when no grows exist) that creates a sample grow with plants and watering logs. This helps first-time users explore the app's features before entering their own data.

## Watering from History

Each row in HistoryView includes a water droplet button that opens the AddWateringLogView pre-configured for that plant. This provides a quick-access watering path directly from the history list.

## Accessibility

- VoiceOver: all interactive elements have accessibilityLabel; decorative images hidden; modal traits on overlays
- Dynamic Type: semantic fonts used throughout; padding scaled for larger text sizes
- Color contrast: custom RGB badge colors maintain white text contrast in both light and dark modes
- Touch targets: minimum 44x44pt on all toolbar buttons

## Device & Orientation

- **Orientation**: Portrait only (iPhone and iPad)
- **Device family**: iPhone and iPad (TARGETED_DEVICE_FAMILY = "1,2")
- **Deployment target**: iOS 17.0
- **Export compliance**: ITSAppUsesNonExemptEncryption = NO (no encryption used)

## iPad Adaptive Layout

The app uses the same stacked navigation flow on iPad as iPhone. `@Environment(\.horizontalSizeClass)` detects iPad (`.regular`) and applies targeted adjustments:

- **Modal overlays** (DeleteConfirmationView, LimitExceededView): capped at 420pt width on iPad
- **Summary grid**: 3 columns on iPad (vs 2 on iPhone) for the 5 metric cells
- **Plant info HStack**: constrained to 500pt max width, centered
- **Retained water chart**: 260pt height on iPad (vs 180pt on iPhone)
- **Lists and forms**: `.insetGrouped` style auto-adapts content width on iPad — no manual constraint needed

## Privacy

- No tracking (NSPrivacyTracking = false)
- No data collection (NSPrivacyCollectedDataTypes empty)
- Only API accessed: UserDefaults (reason CA92.1)
- All data stored locally on device; nothing sent to the internet

## v2 Roadmap

Features planned for future updates:

- **App Icon**: Professional 1024x1024px icon for App Store. Design should reflect watering/plant theme using app's blue palette.
- **Plant Photos**: Allow users to attach a photo to each plant for visual identification
- **Localization**: NSLocalizedString() wrapping for multi-language support
