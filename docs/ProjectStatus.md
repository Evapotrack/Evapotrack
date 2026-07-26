# Evapotrack - Project Status

_Last updated: 2026-07-26_

## Current State

Version 1.0 is live on the App Store (apps.apple.com/app/evapotrack/id6761138265).

## In Progress: Watering Log Photos

The camera-photo-per-watering-log feature is implemented on branch
`claude/matts-hydroponics-outreach-vwiicq` (code, tests, and docs complete).
It has **not yet been compiled or run** — the work was authored in an
environment without Xcode. Before merging or shipping:

- [ ] Build the app target in Xcode (verify strict-concurrency and
      MemberImportVisibility settings compile clean).
- [ ] Run the full test suite, including the new `ImageProcessingTests`.
- [ ] Test camera capture, retake/remove, and the full-screen photo viewer
      on a **physical device** (the Simulator has no camera; the Photo
      section is hidden there by design).
- [ ] Confirm the SwiftData lightweight migration by upgrading an install
      with existing grows/plants/logs.
- [ ] Verify the data export Photo column with and without photos present.

## Blocked: App Store Distribution

Apple Developer account access is currently unavailable: the business phone
number plan expired, and the account is awaiting re-verification/approval
with a new phone number. Until access is restored:

- No TestFlight or App Store builds can be uploaded.
- Code signing for device installs may be limited to free-provisioning
  (7-day) profiles.
- Development and local testing are unaffected — continue merging verified
  work to `main` so a release build is ready once the account is restored.

## Next Up (from code review, not yet started)

1. Insights fallback when the latest log is a full-runoff "flush"
   (retained = 0 currently hides Next/Goal despite rich history).
2. Recent-N or exponentially weighted average for `averageRetained` so
   recommendations track the plant's current stage instead of all-time
   history.
3. Shorten or remove the fixed 3-second launch screen delay.
4. Use temperature/humidity (currently informational) in the
   recommendation algorithm.
