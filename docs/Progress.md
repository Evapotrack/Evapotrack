# Evapotrack - Development Progress

Chronological record of Evapotrack's development from initial commit to current state.

## Phase 1: Foundation (March 1, 2026)

### Core App Architecture
- SwiftUI + SwiftData project setup (iOS 17+, MVVM)
- Data models: Grow, Plant, WateringLog with cascade delete relationships
- Service layer: GrowService, PlantService, WateringLogService
- ViewModel pattern: @Observable @MainActor with configure(modelContext:) pattern
- NavigationStack with typed navigation IDs (GrowNavID, PlantNavID)

### Core Features
- Grow management: create, delete, list with selection
- Plant management: create, delete, list within a grow
- Watering log tracking: water added, runoff collected, date/time, optional temp/humidity
- Automatic calculations: retained volume, runoff %, capacity %, interval hours
- Next watering recommendation algorithm (formula + history blending)
- Max retention capacity calculator (derive from test watering)

### Settings & Configuration
- Water unit selection (mL, L, gallons)
- Temperature unit selection (Celsius, Fahrenheit)
- Appearance mode (Light/Dark, default: Dark)
- Settings persistence via UserDefaults (JSON-encoded)
- Internal unit storage (liters, Celsius) with display-time conversion

### User Interface
- Custom color palette: evPrimaryBlue, evDeepNavy, evFrostBlue, evSlateGray, etc.
- Custom delete confirmation modal (DeleteConfirmationView)
- Launch screen with animated fade-in
- How To guide with context-aware content (general vs. watering-specific)
- Single-select with circle/checkmark indicators
- Empty state views with guidance text

### Polish & Hardening (same day)
- Compact dashboard layout with large titles
- Entity caps (30 grows, 25 plants/grow, 750 total plants)
- Uniqueness validation (grow names, plant names, log timestamps)
- Text input limits (50 chars names, 30 chars pot/medium)
- Time picker constrained to prevent future dates
- Grow rows redesigned with plant count and creation date
- History grouped by day with section headers (Today/Yesterday/Date)
- Section icons for dashboard panels

### Code Quality
- Production audit: error handling, guard clauses, async cleanup
- Grows and plants sorted by most recently created first
- Remove subtitle metrics from plant row (name only)
- Project documentation created (Architecture, DataModel, NavigationMap, Requirements, Specification)
- .gitignore configured

## Phase 2: Data Integrity & Export (March 5, 2026)

### Critical Fix
- SwiftData migration failure fix (store couldn't load after model changes)

### Features
- Limit counters in section headers ("2/30", "5/25")
- LimitExceededView modal when creation limits reached
- Per-grow data export via Settings (text file with formatted tables)
- Export includes temp/humidity columns dynamically per-plant

### Polish
- Data export moved from standalone to per-grow in Settings
- Swipe-back gesture disabled (custom back button)
- Text truncation with `.lineLimit(1).truncationMode(.tail)`
- Watering button added to History view toolbar
- Default appearance changed to Dark mode
- Accessibility labels on toolbar buttons

### Code Quality
- Error propagation improvements across services
- Data integrity and state management hardening

## Phase 3: Visual & Accessibility (March 12, 2026)

### Features
- Temperature and humidity display in expanded watering log rows
- Status badges on plant rows (Healthy/Due Soon/Due Today/Overdue/New)
- Empty state "How to Get Started" link to HowToView
- Dashboard card styling (frosted blue backgrounds on metric cells)
- Retained water chart in History (area + line + point marks, catmullRom interpolation)
- Example data loader in Settings (creates sample grow with 6 watering logs)

### Light Mode Pass
- Replaced system colors (.green/.orange/.red) with fixed RGB in StatusBadgeView
- Increased evFrostBlue card opacity from 0.08 to 0.12 for light mode visibility
- Fixed LimitExceededView icon color for consistent appearance

### VoiceOver Accessibility
- accessibilityLabel on all metric cells, status badges, chart, counters, form inputs
- accessibilityHint on optional fields, chart toggle, calculator, log expansion
- accessibilityHidden on decorative images (empty state icons, launch icon, chevrons)
- accessibilityElement(children: .combine) on metric cells, counters, empty state text
- accessibilityAddTraits(.isModal) on all modal overlays

### Dynamic Type
- LaunchView fonts converted from fixed sizes to semantic Dynamic Type fonts
- Increased padding in StatusBadgeView, WateringLogRowView, HowToView for text scaling

### App Store Preparation
- Portrait-only orientation locked (iPhone and iPad)
- Export compliance declared (ITSAppUsesNonExemptEncryption = NO)
- v2 roadmap documented (app icon, plant photos, localization)

### iPad Adaptive Layout (March 12, 2026)
- Modal overlays (delete confirmation, limit exceeded) constrained to 420pt width on iPad
- Summary grid switches from 2 to 3 columns on iPad via horizontalSizeClass
- Plant info HStack constrained to 500pt max width, centered
- Retained water chart height increased to 260pt on iPad (180pt on iPhone)
- Lists and forms auto-adapt via .insetGrouped — no manual constraint needed

## Current State

- **136 unit tests**, all passing
- **45 Swift source files** across Models, Services, ViewModels, Views, Utilities
- **9 custom color assets** with light/dark variants
- **Privacy manifest**: no tracking, no data collection, UserDefaults only
- **Deployment target**: iOS 17.0
- **Device family**: iPhone and iPad (portrait only)

## Remaining for App Store Submission

1. App icon (1024x1024)
2. Privacy policy URL
3. Support URL
4. App Store metadata (description, keywords, screenshots)
5. Apple Developer Account enrollment
6. Bundle ID and provisioning profiles
7. App Store Connect setup
8. TestFlight testing on physical devices

## v2 Roadmap

- Professional app icon design
- Plant photos for visual identification
- Localization (multi-language via NSLocalizedString)
