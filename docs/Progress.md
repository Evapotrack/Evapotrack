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
- ~~Status badges on plant rows~~ (removed — app recommends how much to water, not when)
- Empty state "How to Get Started" link to HowToView
- Dashboard card styling (frosted blue backgrounds on metric cells)
- Retained water chart in History (area + line + point marks, catmullRom interpolation)
- Example data loader in Settings (creates sample grow with 6 watering logs)

### Light Mode Pass
- Replaced system colors with fixed RGB for consistent contrast
- Increased evFrostBlue card opacity from 0.08 to 0.12 for light mode visibility
- Fixed LimitExceededView icon color for consistent appearance

### VoiceOver Accessibility
- accessibilityLabel on all metric cells, chart, counters, form inputs
- accessibilityHint on optional fields, chart toggle, calculator, log expansion
- accessibilityHidden on decorative images (empty state icons, launch icon, chevrons)
- accessibilityElement(children: .combine) on metric cells, counters, empty state text
- accessibilityAddTraits(.isModal) on all modal overlays

### Dynamic Type
- LaunchView fonts converted from fixed sizes to semantic Dynamic Type fonts
- Increased padding in WateringLogRowView, HowToView for text scaling

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

## Phase 4: Cleanup & Polish (March 13, 2026)

### Feature Changes
- Removed plant status/overdue feature entirely (app recommends how much, not when)
- Moved Max Capacity from Summary to Plant Info panel
- Added Capacity % to Summary panel (retained / maxRetentionCapacity × 100)
- Removed suggested pot sizes and medium types from creation form
- Example data pot size changed from "6 inch" to "Fabric 3 gal"

### History & Chart Improvements
- Chart toggles between chart view and log list (no longer shows both)
- Chart dots limited to 10 evenly spaced points across all logs
- Chart date labels: oldest (left) and most recent (right) below chart corners
- Interval format changed from "2.8 d" to "2d 19h"
- Compact log rows (reduced padding and font sizes)
- Reduced section spacing on dashboard and history screens

### Dead Code Removal
- WateringLogService.mostRecentLog() (unused function)
- WaterUnit.label, TemperatureUnit.label (unused properties)
- AppConstants.appName, appVersion (unused constants)
- DisplayFormatter.intervalHours() (replaced by intervalAdaptive)
- Logger.app, Logger.data (unused categories)

### Documentation Updates
- Specification.md: removed stale water droplet section, fixed algorithm, metric count, badge reference
- Requirements.md: FR-3.7 and FR-4.6 corrected to match implementation
- AppStoreMetadata.md: status badges replaced with Capacity % tracking

## Phase 5: Chart Overlays & UX Polish (March 13–14, 2026)

### Chart Enhancements
- Temperature and humidity data line overlays on retained chart
- Pill-shaped toggle buttons (Retained always-on, Temp, Humidity) below chart header
- Dual Y-axis via ZStack overlay — each data line has independent scale
- When both overlays active, right Y-axis hidden to avoid label overlap
- Chart colors: evPrimaryBlue (retained), evWarmOrange (temperature), evSoftPurple (humidity)
- Dynamic chart header title based on active toggles (e.g., "Retained · Temp · Humidity Over Time")
- Chart shortcut button on PlantDashboardView toolbar (opens HistoryView in chart mode)

### Toolbar Layout Refinements
- Trash and plus buttons grouped in single ToolbarItem (HStack, 12pt spacing) on all screens
- Help button always coupled with gear/settings on leading side
- Chart toggle button on HistoryView trailing side
- Added help button to HistoryView (chart-specific How To context)

### How To Content
- New HowToContext.chart with 4 sections: Reading the Chart, Temperature and Humidity Overlays, What Is Next?, Watering Protocol
- "How to Download Your Grow Data" section added to general context
- "What Is Next?" rewritten for clarity across all contexts
- Updated chart description to accurately reflect all-logs plotting behavior

### Text & Layout Polish
- Increased display text sizes across panels (InsightsPanelView, SummaryPanelView, WateringLogRowView, GrowRowView)
- Unified row padding to 8pt across GrowRowView and PlantRowView
- History log date section headers changed to evPrimaryBlue
- Hardcoded LimitExceededView icon color replaced with evWarmOrange

### Example Data Adjustments
- Humidity values adjusted to 45–65% range
- Temperature values adjusted to 69–91°F range (stored as Celsius internally)

## Current State

- **111 unit tests**, all passing
- **45 Swift source files** across Models, Services, ViewModels, Views, Utilities
- **11 custom color assets** with light/dark variants (added evWarmOrange, evSoftPurple)
- **Privacy manifest**: no tracking, no data collection, UserDefaults only
- **Deployment target**: iOS 17.0
- **Device family**: iPhone and iPad (portrait only)

## Development Time

- **~24 hours** of active Claude Code development time (accounting for session overlap)
- **12 sessions** across 14 calendar days (March 1–14, 2026)
- **Phase 1 (March 1–2):** ~12 hrs — foundation, core features, settings, UI, polish, tests
- **Phase 2 (March 6):** ~3 hrs — data integrity, limits, export, code review
- **Phase 3 (March 12–13):** ~4 hrs — light mode, accessibility, Dynamic Type, App Store prep, iPad layout, code review, App Store prep docs
- **Phase 4 (March 13):** ~2 hrs — status removal, chart/history polish, dead code cleanup, doc sync
- **Phase 5 (March 13–14):** ~3 hrs — chart overlays, toolbar polish, How To content, text sizing

## Completed Pre-Submission Items

- [x] App icon (1024x1024) — in asset catalog
- [x] Privacy policy — `docs/privacy-policy.html`
- [x] Support page — `docs/support.html`
- [x] App Store metadata — `docs/AppStoreMetadata.md`
- [x] Full code review — 111 tests passing, dead code removed

## Next Steps (In Order)

1. **Apple Developer Account** — Enroll at developer.apple.com ($99/year), complete identity verification
2. **Bundle ID** — Register in Apple Developer portal, update Xcode from `Evapotrack.EvapotrackDev` to production ID
3. **Provisioning profiles** — Auto-managed signing in Xcode once Developer Account is active
4. **Enable GitHub Pages** — Settings → Pages → Deploy from `main` / `docs` to publish privacy policy and support URLs
5. **TestFlight build** — Archive in Xcode, upload to App Store Connect, test on physical iPhone and iPad
6. **Physical device testing** — Verify haptics, data persistence, orientation lock, export file saving, Dark/Light mode
7. **Screenshots** — Capture on required simulators (6.7" iPhone, iPad Pro 13") after testing confirms everything works
8. **App Store Connect** — Create app listing, paste metadata, add URLs, upload screenshots, set pricing (Free), age rating (4+)
9. **Submit for review** — Select build, submit to Apple review

## Optional Enhancements (Not Blocking v1)

- **App Store preview video** — 15-30 sec screen recording of core flow
- **Additional test coverage** — Services, ViewModels, DataExportService (~6-8 hrs)

## v2 Roadmap

- Localization — wrap all user-facing strings in `NSLocalizedString()` to support multiple languages. This enables translators to provide `.strings` files for each locale without changing any Swift code. The app already uses hardcoded English strings throughout, so the work involves replacing each literal with `NSLocalizedString("key", comment: "context")` and creating a base `Localizable.strings` file. Once in place, adding a new language is just adding a translated `.strings` file to the project.
