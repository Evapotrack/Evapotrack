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
