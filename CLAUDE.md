# EvapoTrack: notes for future sessions

EvapoTrack is an offline iOS/iPadOS app (SwiftUI + SwiftData, iOS 17+) that tracks plant watering: water added, runoff collected, and the retained water between them. It recommends the next watering amount from the grower's own measurements. Its website is evapotrack.com.

## Start here
- **Where things stand:** `engineering/revision-2/IMPLEMENTATION-REPORT.md` covers what the last revision did, open issues (P0–P3) and the device checklist.
- **What changed and why:** `engineering/revision-2/CHANGELOG-DETAILED.md` describes every file before and after, since `89cc8c8`.
- **Last audit:** `engineering/reviews/2026-09-27-engineering-review.md`.
- **Architecture, data model, navigation and specification:** `engineering/app-docs/`.
- **Why the recommendation model is what it is:** `engineering/research/algorithm/README.md`.

## Current status (update this when it changes)
- Revision 2 is on branch `claude/wonderful-edison-i0ukly` and has **not been merged, compiled, tested or released**. No Swift toolchain was available when it was written.
- Tests: 268 written, 0 run. Build and run them in Xcode first, and expect small compile fixes. One migration test is skipped until a store from the App Store build is captured (`EvapotrackDevTests/Fixtures/README.md`).
- Every claim in the reports is at "implemented + syntax-checked" level only. See the verification-levels table in the implementation report.
- App Store version: still 1.0 (1) in the project. Raise it in Xcode before archiving. Never change signing.
- The website changes in `docs/` describe the photo feature. Publish them only when that release is live.

## Repository layout
- `Evapotrack/`: app sources (App, Models, Services, Services/Photos, ViewModels, Views, Utilities, Resources).
- `EvapotrackDevTests/`: XCTest target (`Support/` holds fixtures and reference models).
- `EvapotrackDev.xcodeproj`: file-system-synchronized groups, so new files join their target automatically. Bundle ID `com.evapotrack.app`.
- `docs/`: **the public website** (GitHub Pages, CNAME evapotrack.com). Everything here is published. Never put internal notes here.
- `engineering/`: internal reports, research, tools and app docs. It isn't published on the site, but the repo is public.
- Gitignored and private: `private/`, `screenshots/`, App Store screenshots, and video assets.

## Rules that are easy to break
- **Schema:** `Models/SchemaV1.swift` is frozen and must match the shipped store forever. Model changes go in a new `SchemaV3` with a migration stage in `Models/Schema.swift`, plus a test in `MigrationTests`. Models are declared as `extension SchemaV2 { @Model nonisolated final class … }` and used through typealiases.
- **Concurrency:** the app target uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` with Swift 5 mode. Pure types (engine, parser, unit conversion, AppConstants, photo processing and store) are `nonisolated`. Image work runs in `Task.detached`. The photo orphan sweep deliberately runs on the main actor.
- **Units:** values are stored unrounded in liters and °C. Rounding happens only in `DisplayFormatter`. Number parsing goes through `NumericInput.parse` (never `Double(text)`). Validation messages take the user's unit.
- **Strings:** every user-facing string is an EN/ES pair in `Utilities/LocalizedStrings.swift` (the `Strings` enum; in-app language switch). Add both languages. Dates use `Strings.locale`.
- **Saves:** go through `modelContext.saveOrRollback(using:action:)`, and services take an injectable `save:` for failure tests.
- **Photos:**
  - Only through PhotosPicker. No camera, `PHPhotoLibrary` or usage descriptions.
  - Files live in `Application Support/WateringPhotos/<uuid>[_thumb].heic`. The model stores only `photoFileID`.
  - Copy the photo before saving a log. Delete files only after the deletion is saved.
  - Don't use file-timestamp or disk-space APIs, which would need privacy-manifest reasons.
- **Recommendation logic:** lives only in `Services/RecommendationEngine.swift` (pure, unit-tested). Change it with simulation evidence (`engineering/research/algorithm/`) and keep it explainable. Don't add weather or other inputs just because they exist.
- **Export format:** it is pinned by `DataExportTests` snapshots. Change the snapshot deliberately.
- **Product scope:** no accounts, cloud, backend, analytics, ads, third-party SDKs, AI or camera. Local and offline is the product.

## Verifying without Xcode
- `python3 engineering/tools/swiftsyntax.py <files>` runs a syntax parse (needs `pip install tree-sitter tree-sitter-swift`). It falsely flags `as? String ?? "1"` in `SettingsView.swift`.
- Python reference models for the engine, the parser and the export are in `engineering/research/`. Use them to compute expected test values.
