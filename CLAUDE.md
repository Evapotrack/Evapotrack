# EvapoTrack: notes for future sessions (branch `main`)

EvapoTrack is an offline iOS/iPadOS app (SwiftUI + SwiftData, iOS 17+). It tracks plant watering: water added, runoff collected, and the retained water between them. It suggests the next watering amount (**Next**) from the grower's own measurements. Its website is evapotrack.com.

## Start here
- **Where things stand and what to do next:** `engineering/plans/2026-10-07-status.md`.
- **The approved plan:** `engineering/plans/2026-10-07-plan.md`. How to do each step: `engineering/plans/2026-10-06-runbook.md`.
- **Every change, and how to restore any prior state:** `engineering/changes/`. Add each new change there: what changed, the prior state, why, and how to undo it.
- **Release history** (which commit became each App Store version): `engineering/releases/README.md`.

## Branches
- `main`: App Store **v1.1 (1)** code (`c063360`), plus the **live website** in `docs/`.
- `release/1.2`: the next release (revision 2 + fixes), unreleased and never compiled. It has its own, more detailed `CLAUDE.md` for the 1.2 code (schema versions, photos, recommendation engine). It reaches `main` only on release day.
- `claude/wonderful-edison-i0ukly` (revision 2 as written) and `claude/matts-hydroponics-outreach-vwiicq` (camera photos, not chosen): kept as history.

## Terms
- **Next:** the app's **suggested amount for the next watering**, an amount of water and not a time. Keep this meaning everywhere.
- **Retained:** water added − runoff. **Runoff %:** runoff ÷ water added. **Goal runoff:** the target runoff % (default 15%). **Max Retention Capacity:** the most the medium takes in during one watering before runoff begins.

## Rules that are easy to break
- **`docs/` is the public website.** GitHub Pages publishes `main`'s `docs/`. evapotrack.com is registered at **Namecheap**, whose DNS points to GitHub Pages, and `docs/CNAME` holds `evapotrack.com`. Never change DNS or `docs/CNAME`, and never put internal notes in `docs/`. Merging into `main` changes the live site within minutes.
- **GitHub never updates the iOS app.** App releases are archived in Xcode on the Mac, uploaded with the Apple Developer account, reviewed by Apple, and released in App Store Connect.
- **Preserve history:** never force-push, rebase a pushed branch, delete a branch or delete a tag. Cloud sessions can't push tags (HTTP 403), so tags are pushed from the Mac.
- **Versions:** commit any version or build change before archiving, and tag the archived commit.
- **Product scope:** local and offline, with no accounts, cloud, analytics, ads or third-party SDKs. The app, screenshots and store listing describe growing media and methods, never a crop (App Store guideline 1.4.3).
- **Strings:** every user-facing string is an EN/ES pair in `Evapotrack/Utilities/LocalizedStrings.swift`.
