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

## Phase 6: Localization (March 14, 2026)

### In-App Language Switching
- English/Spanish language toggle via segmented picker (EN/ES) in Settings
- Custom `Strings` enum with ~200 computed properties for all user-facing text
- `nonisolated(unsafe) static var current: AppLanguage` synced on load/save/reset
- Language persisted in UserSettings (backward-compatible decoder)
- Default language: English

### Actor Isolation Fixes
- `nonisolated(unsafe) let plant: Plant` on PlantDashboardViewModel and AddWateringLogViewModel
- `nonisolated init` on ViewModels to satisfy SwiftUI View protocol requirements
- `nonisolated protocol DateProviding: Sendable` to prevent @MainActor inference
- `nonisolated enum ValidationResult: Equatable, Sendable` for test compatibility

### App Display Name
- Changed app display name from "EvapotrackDev" to "Evapotrack" via Info.plist build settings
- Xcode project and folder remain "EvapotrackDev"

### Files Changed
- New: `LocalizedStrings.swift` (~530 lines)
- Modified: 27 existing files (all Views, ViewModels, Services, Models, Utilities)

## Current State

- **111 unit tests**, all passing
- **46 Swift source files** across Models, Services, ViewModels, Views, Utilities
- **11 custom color assets** with light/dark variants (added evWarmOrange, evSoftPurple)
- **Privacy manifest**: no tracking, no data collection, UserDefaults only
- **Deployment target**: iOS 17.0
- **Device family**: iPhone and iPad (portrait only)
- **Languages**: English (default), Spanish — in-app switching

## Development Time

- **~35 hours** of active Claude Code development time (accounting for session overlap)
- **17 sessions** across 22 calendar days (March 1–22, 2026)
- **Phase 1 (March 1–2):** ~12 hrs — foundation, core features, settings, UI, polish, tests
- **Phase 2 (March 6):** ~3 hrs — data integrity, limits, export, code review
- **Phase 3 (March 12–13):** ~4 hrs — light mode, accessibility, Dynamic Type, App Store prep, iPad layout, code review, App Store prep docs
- **Phase 4 (March 13):** ~2 hrs — status removal, chart/history polish, dead code cleanup, doc sync
- **Phase 5 (March 13–14):** ~3 hrs — chart overlays, toolbar polish, How To content, text sizing
- **Phase 6 (March 14):** ~3 hrs — EN/ES localization, actor isolation fixes, app display name, code review
- **Phase 7 (March 14–15):** ~1 hr — example data fix, How To chart sections, Settings layout
- **Phase 8 (March 15):** ~1 hr — dashboard layout fix, full audit, App Store preparedness docs
- **Phase 9 (March 21):** ~2 hrs — copyright notices, dark screenshots, copyright deposit, documentation
- **Phase 10 (March 21–22):** ~4 hrs — pre-launch website, screenshot processing, DNS config, copyright/trademark

## Completed Pre-Submission Items

- [x] App icon (1024x1024) — in asset catalog
- [x] Privacy policy — `docs/privacy-policy.html` (live at https://evapotrack.com/privacy-policy.html)
- [x] Support page — `docs/support.html` (live at https://evapotrack.com/support.html)
- [x] GitHub Pages — repo public, pages deployed from main/docs
- [x] App Store metadata — `AppStoreMetadata.md` (name, subtitle, description, keywords, categories)
- [x] Privacy manifest — no tracking, no data collection, UserDefaults only
- [x] Export compliance — ITSAppUsesNonExemptEncryption = NO in Info.plist
- [x] App display name — "Evapotrack" (not "EvapotrackDev")
- [x] Light mode screenshots — 19 images in `screenshots/light-mode/`
- [x] Dark mode screenshots — 16 images in `screenshots/dark-mode/`, 5 processed with bezels in `docs/screenshots/`
- [x] Full code audit — 111 tests passing, no dead code, no debug artifacts, no security issues
- [x] Localization — EN/ES in-app switching complete
- [x] Pre-launch website — live at https://evapotrack.com (dark theme, 5 screenshots, feature cards)
- [x] DNS configured — evapotrack.com pointing to GitHub Pages (A records + CNAME)

## Completed Business & Legal

- [x] **Apple ID created** — dedicated Evapotrack Apple ID (March 18)
- [x] **Apple Developer Program** — enrolled (March 18)
- [x] **Domains purchased** — evapotrack.com and evapotrack.app on Namecheap (March 18)
- [x] **Copyright submitted** — U.S. Copyright Office confirmed receipt (March 21)
- [x] **Trademark submitted** — USPTO application filed, Standard Character Mark, Class 009 (March 22)

## Phase 9: Copyright & Documentation (March 21, 2026)

- Added `© 2026 Evapotrack. All rights reserved.` copyright notice to all 51 Swift files
- Captured 16 dark mode screenshots in `screenshots/dark-mode/`
- Moved Progress.md and AppStoreMetadata.md out of `docs/` (not public GitHub Pages)
- Scrubbed sensitive business details from Progress.md
- Documented March 18 business milestones (Apple ID, Developer Program, domains, trademark, copyright)
- Prepared copyright deposit materials (`copyright-deposit/evapotrack-copyright-deposit.zip`)
  - Source code: first/last 25 pages (2,503 lines) with copyright headers
  - 16 dark mode screenshots
- Copyright application filled out on eCO (copyright.gov) — Standard Application, Literary Work
  - Upload blocked by scheduled maintenance (Sat 10pm–Sun 6am ET)

## Phase 10: Website, DNS, Copyright & Trademark (March 21–22, 2026)

### Pre-Launch Website
- Built dark-themed landing page at `docs/index.html`
- 5 dark mode screenshots with iPhone-style bezel frames (cropped from Xcode simulator, 680x1468px each)
- 8 feature cards highlighting core capabilities
- Privacy and support pages converted from light to dark theme with back navigation links
- Open Graph + Twitter Card meta tags for social sharing previews
- Responsive design with mobile breakpoint at 640px
- "Coming Soon to the App Store" badge

### Screenshot Processing
- Source: `screenshots/dark-mode/` (970x1836px Xcode simulator captures)
- Cropped to screen content: (157, 229, 813, 1673) → 656x1444px
- Added iPhone-style bezel frame (12px, gray-blue #374158/#4b5870)
- Rounded corners (38px radius)
- Final: 5 processed PNGs in `docs/screenshots/`, total 856KB

### DNS Configuration
- **evapotrack.com** — 4 A records (185.199.108–111.153) + www CNAME → evapotrack.github.io on Namecheap
- **evapotrack.app** — A records set but reserved for brand protection only (.app TLD enforces HTTPS via HSTS preload; Namecheap redirect won't work)
- CNAME file added to `docs/CNAME` pointing to evapotrack.com
- Site live at https://evapotrack.com

### Copyright Confirmed
- U.S. Copyright Office confirmed receipt of application and payment on 2026-03-21 at 9:51 PM ET
- Standard Application, Literary Work, Computer Program
- Deposit: `copyright-deposit/evapotrack-copyright-deposit.zip`

### Trademark Submitted
- USPTO trademark application filed for "EVAPOTRACK" on 2026-03-22
- Standard Character Mark, Class 009 (Computer Software)
- Section 1(b) Intent to Use basis
- Free-form goods/services description: "Downloadable mobile application software for tracking plant watering, monitoring water retention, and providing watering recommendations"
- Filing fee paid (includes free-form surcharge)
- After app launches: file Allegation of Use with App Store screenshot as specimen

### Development Time
- ~4 hrs — website build, screenshot processing, DNS config, copyright/trademark documentation

## Next Steps (In Order)

1. ~~Upload copyright deposit~~ — **DONE** (confirmed received 2026-03-21)
2. ~~Build pre-launch website~~ — **DONE** (live at https://evapotrack.com)
3. ~~Submit trademark~~ — **DONE** (USPTO application filed 2026-03-22)
4. **Bundle ID** — **BLOCKED**: Apple Developer enrollment stuck on "Pending" (4+ days elapsed). Support ticket submitted March 22. Do not re-purchase. Xcode account added. Once resolved: Register in Certificates, Identifiers & Profiles → Identifiers → App IDs; update Xcode bundle identifier from `Evapotrack.EvapotrackDev` to registered ID (e.g., `com.evapotrack.app`)
5. **Configure Signing** — Xcode → Signing & Capabilities → select Team, enable "Automatically manage signing"
6. **TestFlight Build & Testing** — Xcode: Product → Archive → Distribute App → App Store Connect; install via TestFlight on physical devices; run full device testing checklist
7. **App Store Connect Listing** — Create app (appstoreconnect.apple.com → My Apps → +); fill all metadata, screenshots, build selection
8. **Submit for App Store Review** — Select TestFlight build, verify all fields complete, submit; typical review: 24-48 hrs

## Optional Enhancements (Not Blocking v1)

- **App Store preview video** — 15-30 sec screen recording of core flow
- **Additional test coverage** — Services, ViewModels, DataExportService (~6-8 hrs)
- **evapotrack.app redirect** — Consider Cloudflare if redirect from .app to .com needed later

## Phase 7: Post-Localization Polish (March 14–15, 2026)

### Bug Fixes
- Example data button no longer disabled after delete/try cycles (removed stale `exampleDataLoaded` state)

### How To Content
- Added "Reading the Chart" and "Temperature and Humidity Overlays" sections to plant dashboard How To context

### Settings Layout
- Merged Display Units and Theme into single section (eliminates scroll on iPhone)
- Reduced vertical padding and font sizes for compact fit
- Reset button padding tightened

### Code Review
- Full three-part review: UI/UX, models/services/logic, App Store readiness
- Fixed force unwrap crash risk in HistoryView chart (replaced `first!/last!` with guard)
- Verified `.foregroundColor()` usage in HowToView is correct (required for Text concatenation)
- No critical bugs, no memory leaks, no debug code found in shipping source

### Development Time
- ~1 hr — bug fix, How To content, Settings layout, code review

## Phase 8: Dashboard Layout & Audit (March 15, 2026)

### Layout Fix
- PlantDashboardView listSectionSpacing reduced from 8 to 4 (eliminates slight scroll)
- SummaryPanelView and InsightsPanelView grid padding reduced from 4 to 2

### Full App Audit
- 111 tests passing (zero failures)
- No debug artifacts, no security issues
- Force unwrap in HistoryView chart verified safe (guarded by `count >= 2`)

### Potential Future Cleanup (not blocking v1)
- Remove unused `Date.daysBetween()` in Extensions.swift (line 32)
- Remove 5 unused color aliases in Color+Evapotrack.swift: `evBorder`, `evIcon`, `evIconInactive`, `evButtonPrimary`, `evButtonDisabled`
- Replace force unwraps after `.filter` in HistoryView chart (temp line 427, humidity line 454) with `if let` for safer pattern
- Add error logging in PlantListView `deletePlant()` catch block

### App Store Preparedness
- Expanded Next Steps with detailed step-by-step submission pipeline
- Documented full App Store Connect listing checklist (categories, pricing, privacy, screenshots, build)
- Added TestFlight testing checklist (14 items)
- Updated Completed Pre-Submission Items (11 items verified)

### Development Time
- ~1 hr — layout fix, audit, App Store preparedness documentation

## v2 Roadmap

- ~~Localization~~ — completed in Phase 6 (EN/ES in-app switching)
