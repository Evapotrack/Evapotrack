# Evapotrack - Requirements

## Product Overview

Evapotrack is an iOS 17+ application for tracking and optimizing plant watering through evapotranspiration data. Users log watering events, and the app calculates retention metrics and recommends next watering amounts based on historical patterns.

## Functional Requirements

### FR-1: Grow Management
- FR-1.1: Users can create grows with a unique name (1-50 characters, case-insensitive uniqueness).
- FR-1.2: Users can delete grows. Deleting a grow cascade-deletes all plants and watering logs.
- FR-1.3: Maximum 30 grows per user.
- FR-1.4: Grows are immutable after creation (no editing).
- FR-1.5: Grows are listed by creation date, newest first.

### FR-2: Plant Management
- FR-2.1: Users can create plants within a grow with: name, pot size, medium type, max retention capacity, and optional goal runoff %.
- FR-2.2: Plant names must be unique within a grow (case-insensitive).
- FR-2.3: Maximum 25 plants per grow.
- FR-2.4: Plants are immutable after creation (no editing).
- FR-2.5: Users can delete plants. Deleting a plant cascade-deletes all watering logs.
- FR-2.6: Plants include a calculator to derive max retention capacity from a test watering (water added - runoff = retention).
- FR-2.7: Plants are listed by creation date, newest first.

### FR-3: Watering Log Management
- FR-3.1: Users can log watering events with: water added, runoff collected, date/time, and optional temperature and humidity.
- FR-3.2: Two logs cannot share the same timestamp (compared to the minute) for one plant.
- FR-3.3: Users can delete individual watering logs.
- FR-3.4: Logs are immutable after creation (no editing).
- FR-3.5: Date/time cannot be in the future.
- FR-3.6: History view includes a toggleable chart showing retained water volumes over time.
- FR-3.7: History view toolbar includes an add button to quickly log a new watering for that plant.
- FR-3.8: Users can optionally attach one photo to a watering log, captured with the camera at log-creation time only (no photo library; no adding, replacing, or removing after save — logs remain fully immutable).
- FR-3.9: Photos are processed before storage: downscaled to a longest edge of 2048 px, EXIF/GPS metadata stripped, JPEG-compressed to at most 800 KB. If processing fails, the log saves without a photo.
- FR-3.10: In history, collapsed rows with a photo show a camera glyph; expanding a log reveals a tappable thumbnail that opens a full-screen zoomable viewer (pinch 1x-4x, double-tap zoom toggle).
- FR-3.11: The photo section only appears on devices with a camera; deleting a log deletes its photo.

### FR-4: Calculations & Insights
- FR-4.1: Retained volume = water added - runoff collected (computed on creation).
- FR-4.2: Runoff % = (runoff / water added) x 100 (computed on creation).
- FR-4.3: Interval hours between consecutive logs recalculated on add/delete.
- FR-4.4: Capacity % = (retained / max retention capacity) x 100, capped at 105%.
- FR-4.5: Average retained computed from all logs for a plant.
- FR-4.6: Next water recommendation blends most recent retained with historical average (50/50) and divides by retention factor.
- FR-4.7: Goal runoff amount computed from next recommendation and goal %.

### FR-5: Display & Units
- FR-5.1: Water volume displayed in user-selected unit (mL, L, or gal).
- FR-5.2: Temperature displayed in user-selected unit (C or F).
- FR-5.3: All stored values use internal units (liters, Celsius) — never rounded.
- FR-5.4: Rounding is display-only, controlled by unit precision.

### FR-6: Settings
- FR-6.1: User can switch water unit (mL/L/gal).
- FR-6.2: User can switch temperature unit (C/F).
- FR-6.3: User can switch appearance mode (Day/Dark).
- FR-6.4: Settings persist across app launches via UserDefaults.
- FR-6.5: Reset to defaults available.
- FR-6.6: Example data loader available on the My Grows screen when no grows exist (creates sample grow, plant, and logs for first-time users).
- FR-6.7: User can switch language between English and Spanish (in-app, no device restart required).

### FR-7: Help & Onboarding
- FR-7.1: Context-aware help (general context from list views, watering context from dashboard).
- FR-7.2: Expandable FAQ-style sections with only one open at a time.

## Non-Functional Requirements

### NFR-1: Data Storage
- All data stored locally via SwiftData. No network calls, no cloud sync, no third-party SDKs.
- Watering-log photos use SwiftData external storage (blobs live beside the database, not inside it) and are removed automatically with their log via cascade rules.

### NFR-2: Performance
- Entity caps (30 grows, 25 plants/grow) keep SwiftData performant on older devices.
- Maximum theoretical entities: 750 plants, ~unlimited logs per plant.

### NFR-3: Platform
- iOS 17.0+ minimum deployment target.
- SwiftUI with SwiftData persistence.
- Supports iPhone and iPad in portrait orientation.

### NFR-4: Accessibility
- All interactive elements have accessibility labels.
- High contrast color palette with light/dark mode support.
- Minimum 44pt tap targets for all buttons.

### NFR-5: Security & Privacy
- No user accounts, no network requests, no analytics.
- All data remains on-device.
- Photos are stripped of all EXIF and GPS metadata before storage; camera access is requested only when the user taps Take Photo (NSCameraUsageDescription provided).
