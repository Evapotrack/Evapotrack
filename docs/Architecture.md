# Evapotrack - Architecture

## Directory Structure

```
Evapotrack/
  App/
    EvapotrackApp.swift          # @main entry point, model container, settings injection
    AppConstants.swift            # Validation bounds, algorithm params, entity caps
  Models/
    Grow.swift                    # @Model: grow group (root entity)
    Plant.swift                   # @Model: plant with retention capacity
    WateringLog.swift             # @Model: single watering event
    UserSettings.swift            # Codable: display units, appearance mode, language
  Services/
    GrowService.swift             # CRUD for Grow entities (with limit enforcement)
    PlantService.swift            # CRUD for Plant entities (with limit enforcement)
    WateringLogService.swift      # CRUD + interval recalculation for logs
    WateringCalculationService.swift  # Pure algorithm functions
    ValidationService.swift       # Human-readable validation results
    UnitConversionService.swift   # Liters/Celsius to/from display units
    HapticService.swift           # UIFeedbackGenerator wrappers
    DataExportService.swift       # Plain-text grow data export + FileDocument
    ServiceError.swift            # Shared error type for service-layer operations
  ViewModels/
    SettingsViewModel.swift       # UserDefaults-backed settings
    CreateGrowViewModel.swift     # Form state for grow creation
    CreatePlantViewModel.swift    # Form state + calculator for plant creation
    AddWateringLogViewModel.swift # Form state for watering log entry
    PlantDashboardViewModel.swift # Dashboard data loading and computed insights
  Views/
    GrowList/
      GrowListView.swift          # Root view, owns NavigationStack
      GrowRowView.swift           # Single grow row component
    PlantList/
      PlantListView.swift         # Plant list within a grow
      PlantRowView.swift          # Single plant row component
    PlantDashboard/
      PlantDashboardView.swift    # Plant detail: info, summary, insights, history link
      SummaryPanelView.swift      # Last event metrics grid
      InsightsPanelView.swift     # Average, next, goal grid
      HistoryPanelView.swift      # History link with log count
      HistoryView.swift           # Full log list with expand/select/delete
      WateringLogRowView.swift    # Expandable log row
    CreateGrow/
      CreateGrowView.swift        # Grow creation form
    CreatePlant/
      CreatePlantView.swift       # Plant creation form with calculator
    AddWateringLog/
      AddWateringLogView.swift    # Watering log entry form
    Settings/
      SettingsView.swift          # Unit pickers, theme toggle, data export, reset
    HowTo/
      HowToView.swift             # Context-aware help sections
    Components/
      LaunchView.swift            # Animated launch screen
      DeleteConfirmationView.swift # Reusable delete modal overlay
      LimitExceededView.swift     # Reusable limit-exceeded modal overlay

  Utilities/
    Validators.swift              # Pure validation functions
    DisplayFormatter.swift        # Unit-aware display formatting
    Extensions.swift              # Date, View, Text extensions
    DateProvider.swift            # Protocol for testable date injection
    LocalizedStrings.swift        # EN/ES bilingual string enum (~530 lines)
    Logger.swift                  # OSLog subsystem categories
    Color+Evapotrack.swift        # Semantic color aliases
  Resources/
    Assets.xcassets/              # App icon, color sets (light/dark)
```

## Layer Diagram

```
┌─────────────────────────────────┐
│           Views (SwiftUI)       │
│  GrowListView, PlantListView,  │
│  PlantDashboardView, Forms...  │
├─────────────────────────────────┤
│         ViewModels (@Observable)│
│  CreateGrowVM, CreatePlantVM,  │
│  AddWateringLogVM, DashboardVM │
├─────────────────────────────────┤
│        Services (@MainActor)    │
│  GrowService, PlantService,    │
│  WateringLogService, CalcSvc   │
├─────────────────────────────────┤
│      Models (@Model / Codable)  │
│  Grow, Plant, WateringLog,     │
│  UserSettings                   │
├─────────────────────────────────┤
│         SwiftData / UserDefaults│
└─────────────────────────────────┘
```

## Data Flow

1. User interacts with a View.
2. View delegates to ViewModel (form state, validation).
3. ViewModel calls Service for persistence.
4. Service operates on ModelContext (insert, delete, save).
5. SwiftData notifies @Query observers, triggering UI refresh.
6. For non-@Query views (PlantListView), parent relationship arrays update automatically via SwiftData's reference-type semantics.

## Threading Model

All ViewModels and Services are annotated `@MainActor`. SwiftData's ModelContext is main-actor-isolated. No background threads or async operations are used — all computation is synchronous and fast enough for the data scale.

## Dependency Injection

- **ModelContext**: Injected via `@Environment(\.modelContext)` in Views, passed to VMs via `configure(modelContext:)`.
- **SettingsViewModel**: Injected via `@Environment(SettingsViewModel.self)` from EvapotrackApp.
- **DateProvider**: Protocol-based injection for testability (SystemDateProvider in production, MockDateProvider in tests).
