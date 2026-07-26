# Evapotrack - Release Plan: v1.1 (Watering Log Photos)

_Last updated: 2026-07-26. Companion to ProjectStatus.md._

This plan covers what to do the moment Apple Developer account access is
restored: first audit the account's health, then ship the photo update.
Phases 0 and 2 need no account access and can be done now.

---

## Phase 0 — While Waiting (no account needed)

- [ ] Complete the verification checklist in ProjectStatus.md (build, tests,
      physical-device camera test, migration check, export check).
- [ ] Merge the verified feature branch to `main`.
- [ ] Draft release notes, EN and ES (photos are user-facing; keep parity
      with the app's bilingual support). Suggested EN copy:
      "New: attach a photo to each watering log. Snap a picture when you
      water, then view it full-screen from the log's history entry. Photos
      stay on your device, like all your data."
- [ ] Decide whether App Store screenshots will be refreshed to show the
      photo feature (optional for this release, can follow in 1.1.1).

## Phase 1 — Account Health Audit (day access is restored)

Do this before touching the release; a lapsed account can have several
broken things at once.

1. **Apple ID + 2FA**: sign in at developer.apple.com and
   appstoreconnect.apple.com. Update the trusted phone number list to the
   new number FIRST (Settings > Sign-In & Security on the Apple ID), and
   remove the dead number so 2FA can't lock the account again.
2. **Membership**: confirm the Apple Developer Program membership is
   Active, note the renewal date, and turn on auto-renew with a payment
   method that doesn't depend on the old phone plan. If the membership
   itself lapsed (not just phone verification), re-enroll under the same
   legal entity so the existing app listing is retained.
3. **Legal entity**: verify the organization's D-U-N-S/legal-entity info
   still matches; an expired business number can cascade into entity
   re-verification requests from Apple.
4. **Agreements, Tax, Banking** (App Store Connect): check for
   re-acceptance prompts on the Paid/Free Apps agreements. Any pending
   agreement blocks submissions silently.
5. **App availability**: confirm Evapotrack (id6761138265) is still
   "Ready for Sale". If it was Removed from Sale during the lapse, restore
   availability before shipping the update.
6. **Signing assets**: check Certificates, Identifiers & Profiles.
   Revoke/regenerate any expired Apple Distribution certificates and let
   Xcode automatic signing recreate profiles. Confirm the
   `com.evapotrack.app` identifier is intact.
7. **Users, keys, devices**: review team members, App Store Connect API
   keys, and registered devices for anything stale or unexpected —
   standard hygiene after any loss-of-access period.
8. **Baseline the numbers**: sales/downloads have not been checked since
   launch, and expectations are low (zero marketing to date, niche
   data-driven audience). While in App Store Connect, pull App Analytics
   (impressions, product page views, downloads, retention) and Sales &
   Trends since launch, and note the baseline in ProjectStatus.md. Whatever
   the numbers are, they become the "before" for the 1.1 release and any
   future marketing — low numbers here are expected and useful, not bad
   news. Check Ratings & Reviews for anything needing a response.

## Phase 2 — Release Build (account restored, Phase 0 done)

1. Bump `MARKETING_VERSION` to 1.1 and increment
   `CURRENT_PROJECT_VERSION` in the project settings.
2. Archive (Any iOS Device) in Xcode; validate the archive.
3. Upload to App Store Connect; confirm processing completes (the new
   camera permission string will surface here if anything is wrong).
4. TestFlight internal build: install on a physical device, exercise the
   photo capture -> history -> full-screen viewer path once more on the
   release build, plus an upgrade-in-place over the App Store version.

## Phase 3 — App Store Submission

1. **App Privacy**: the "Data Not Collected" declaration remains accurate —
   photos are stored on-device only, never transmitted. No privacy label
   change should be needed; re-confirm the questionnaire anyway since
   camera use is new.
2. **Version metadata**: release notes (EN + ES), updated description line
   mentioning photos if desired.
3. **App Review notes**: state plainly that the camera is used solely to
   attach plant photos to watering logs, stored locally, no account or
   network. This preempts the most likely reviewer question.
4. Submit with **phased release** enabled (halts are possible if a
   migration issue slips through) and manual release or auto — either is
   fine at this app's scale.
5. Monitor review status; typical turnaround is 1-2 days. If rejected,
   respond in the Resolution Center rather than resubmitting blind.

## Phase 4 — Post-Launch

- [ ] Verify the update installs cleanly over 1.0 from the App Store on a
      real device (final migration confirmation).
- [ ] Watch Xcode Organizer crash reports for the first week, especially
      anything in image decode paths on older devices.
- [ ] Tag the release in git (`v1.1`) and update ProjectStatus.md.
- [ ] Resume the roadmap items in ProjectStatus.md (insights flush
      fallback, recent-N average, launch delay, temp/humidity in the
      algorithm) for 1.2.
- [ ] **Low-effort marketing window**: the 1.1 release is a natural hook
      for the first real outreach push — the photo feature gives growers a
      visible reason to look. Candidates, roughly in order of effort:
      grow-shop/community outreach on X (drafts already exist for
      @MattsHydro-style shops), posts in grower forums/subreddits where
      runoff-tracking is already discussed, and refreshed App Store
      screenshots + keyword pass (ASO) targeting "runoff", "coco coir",
      "watering tracker". Expectation stays modest: this is a
      work-required, data-driven niche — the goal is finding the small
      audience that already measures runoff, not volume installs.

## Contingencies

- **Account restoration stalls**: escalate via Apple Developer Support
  (phone support is fastest for membership/identity issues) and reference
  the case number each time; identity re-verification for organizations
  can take 2-4 weeks.
- **Membership fully expired and app delisted**: re-enrollment under the
  same legal entity restores the listing and its reviews; do not create a
  new app record — that would orphan existing users' update path.
- **Certificate revocation broke local device installs**: regenerating the
  distribution certificate does not affect the shipped app; only new
  builds need the new certificate.
