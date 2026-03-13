# Evapotrack - Data Model

## Entity Relationship Diagram

```
┌──────────────┐       ┌──────────────┐       ┌──────────────────┐
│     Grow     │ 1───* │    Plant     │ 1───* │   WateringLog    │
├──────────────┤       ├──────────────┤       ├──────────────────┤
│ id: UUID     │       │ id: UUID     │       │ id: UUID         │
│ growName     │       │ plantName    │       │ waterAdded       │
│ createdAt    │       │ potSize      │       │ runoffCollected  │
│              │       │ mediumType   │       │ dateTime         │
│ plants: []   │       │ maxRetention │       │ tempCelsius?     │
│              │       │ goalRunoff%  │       │ humidityPercent? │
│              │       │              │       │ retained         │
│              │       │ wateringLogs │       │ runoffPercent    │
│              │       │ grow?        │       │ intervalHours?   │
│              │       │              │       │ plant?           │
└──────────────┘       └──────────────┘       └──────────────────┘
     cascade                cascade
```

## Grow

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | UUID | Yes | @Attribute(.unique), auto-generated |
| growName | String | Yes | 1-50 chars, unique (case-insensitive) |
| createdAt | Date | Yes | Set on creation |
| plants | [Plant] | Yes | @Relationship(deleteRule: .cascade) |

## Plant

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | UUID | Yes | @Attribute(.unique), auto-generated |
| plantName | String | Yes | 1-50 chars, unique within grow |
| potSize | String | Yes | Descriptive (e.g. "Fabric 3 gal") |
| mediumType | String | Yes | Descriptive (e.g. "soil") |
| maxRetentionCapacity | Double | Yes | Liters, 0.001-100.0 |
| goalRunoffPercent | Double | Yes | 0.1-99.9, defaults to 15.0 |
| wateringLogs | [WateringLog] | Yes | @Relationship(deleteRule: .cascade) |
| grow | Grow? | No | Inverse of Grow.plants |

## WateringLog

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| id | UUID | Yes | @Attribute(.unique), auto-generated |
| waterAdded | Double | Yes | Liters, clamped >= 0.001 |
| runoffCollected | Double | Yes | Liters, >= 0 and < waterAdded |
| dateTime | Date | Yes | Not future, unique per plant (minute) |
| temperatureCelsius | Double? | No | -50 to 60 C |
| humidityPercent | Double? | No | 0-100% |
| retained | Double | Computed | waterAdded - runoffCollected |
| runoffPercent | Double | Computed | (runoff / waterAdded) x 100 |
| intervalHours | Double? | System | Hours since previous log, recalculated |
| plant | Plant? | No | Inverse of Plant.wateringLogs |

## UserSettings (UserDefaults, not SwiftData)

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| waterUnit | WaterUnit | .liters | mL, L, or gal |
| temperatureUnit | TemperatureUnit | .fahrenheit | C or F |
| appearanceMode | AppearanceMode | .dark | Dark or Light |

## Cascade Delete Rules

- Deleting a **Grow** deletes all its **Plants** and their **WateringLogs**.
- Deleting a **Plant** deletes all its **WateringLogs**.
- Deleting a **WateringLog** triggers interval recalculation for remaining logs.

## Storage Details

- **SwiftData** manages Grow, Plant, and WateringLog as @Model classes.
- **UserDefaults** stores UserSettings as JSON via `AppConstants.userSettingsKey`.
- All numeric values stored unrounded in internal units (liters, Celsius).
- Display formatting applied at render time only.

## Entity Caps

| Cap | Value | Rationale |
|-----|-------|-----------|
| Max grows | 30 | SwiftData performance on older devices |
| Max plants per grow | 25 | Prevents excessively long lists |
| Max theoretical plants | 750 | 30 x 25 |

Limits are enforced at both the ViewModel layer (UI gating) and the Service layer (throws `ServiceError.limitExceeded`).
