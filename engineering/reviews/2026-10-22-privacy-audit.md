# Privacy and sensitive-information audit, 2026-10-22

- **Requested:** make sure sensitive information in this public repository is private, or removed where appropriate.
- **Scope:** all 6 branches on GitHub (`main`, `claude/vibrant-noether-xzeec1`, `release/1.2`, `claude/wonderful-edison-i0ukly`, `claude/matts-hydroponics-outreach-vwiicq`, `website/v1.1-accuracy`). Also every commit in the history (177), deleted files, commit messages, and the metadata in all images and the video.
- **Searched for:** home address, birth year, phone numbers, personal email addresses, passwords, API keys, private keys, signing certificates and provisioning profiles, costs and fees, order numbers, and development hours.
- This document deliberately does not repeat any of the sensitive values it found.

## Findings

| # | What | Where | Verdict |
|---|---|---|---|
| 1 | Home address, birth year, full legal name from the copyright certificate and USPTO record | Nowhere in the repository: not in files, history or commit messages. The certificate photo and USPTO PDF were never committed | ✅ Clean |
| 2 | Passwords, API keys, private keys, `.p12`/`.p8`/`.cer`, provisioning profiles, `.env` | Nowhere, in any branch or commit | ✅ Clean. `.gitignore` now blocks them anyway (below) |
| 3 | Image and video metadata | All PNGs: pixel size and "Screenshot" only. No GPS, device or owner fields. `walkthrough.mp4`: creation time and encoder only | ✅ Clean |
| 4 | iPhone screenshots (`engineering/releases/v1.1/device-screenshots/`) | Example data only. Status bar shows time, signal and battery; no notifications or personal content | ✅ Clean |
| 5 | Support email `evapotrack@proton.me` | Website support and privacy pages, git author metadata, these records | ✅ Public on purpose (the App Store requires a support contact) |
| 6 | Apple Developer Team ID in `project.pbxproj` | All branches | ✅ Not secret: it is embedded in every signed app and needed to build |
| 7 | Developer name in git author metadata | Every commit since 2026-03-01 | ✅ Already public: an individual developer's name is shown as the seller on the App Store |
| 8 | App price, `$99/year` program fee | Commit message and old docs | ✅ Public information |
| 10 | **A different person's full name** (the Mac account name Xcode wrote into file headers, and an `xcuserdata` folder name) | First commit `87f5ee3` (2026-03-01): template files' "Created by" lines. Removed from current files on 2026-03-12 (`941d10a`); still readable in history | ⚠️ **Only in history.** Xcode boilerplate, not authorship; but it is someone's name. Owner to confirm whose |
| 11 | Apple account-recovery notes (lost access when a business phone plan expired; the 2FA and re-verification steps) | `docs/ReleasePlan.md` and `docs/ProjectStatus.md` on the kept branch `claude/matts-hydroponics-outreach-vwiicq` (2026-07-26). No phone number, password or code | ⚠️ Account-security context; out of date (access was restored before v1.1 shipped) |
| 9 | **Old `Progress.md`** (at `docs/Progress.md`, then `Progress.md`), removed on 2026-03-22 (`b5770f6`, "keep development hours off public repo") | **Still readable in past commits** (2026-03-12 → 2026-03-22). It contains development hours, the trademark filing fee, an Apple Developer enrollment order number, and notes on an Apple support ticket. Nothing that gives access to an account | ⚠️ **Only in history.** Removing it needs a history rewrite (decision below) |

## Done in this audit

- `.gitignore` now blocks signing files and credentials (`*.p12`, `*.p8`, `AuthKey_*.p8`, `*.cer`, `*.mobileprovision`, `.env`, `*.pem`, `*.key`). It also blocks certificate scans and photos (`*certificate*.jpg/png/pdf`), which belong in `private/`.
- `.gitignore`'s `screenshots/` rule became `/screenshots/`. The old rule also matched the website's `docs/screenshots/`, so a new website screenshot would have been silently left out of a commit. Files already tracked are unaffected.

## GitHub facts (2026-10-22)

- `Evapotrack` is a **personal account**, not an organization. `Evapotrack/Evapotrack` is public: **0 forks, 0 stars**, and it has GitHub Pages on (evapotrack.com).
- The account's only other public repository is `cantillon-crush`, which is unrelated and outside this audit. All other repositories, including `Evapotrack-Android`, are private.

## Decision (2026-10-23)

**Option C1 approved.** The website moves to a new public repository, then this repository becomes private. History is not rewritten. Steps: [`../plans/2026-10-23-website-move.md`](../plans/2026-10-23-website-move.md).
- `cantillon-crush` also goes private (owner's choice).
- Finding 10's name is probably a friend's (the laptop used early on). Going private covers it; nothing more is needed.

## Recommendation (2026-10-22)

**Make `Evapotrack/Evapotrack` private, and keep evapotrack.com public. Don't rewrite history.**

- Going private hides items 9–11 and the source code all at once. Every commit hash, record and PR link stays valid, and the "never force-push" rule is kept.
- A history rewrite (option B) only hides items 9 and 10. It breaks every record, and doesn't recall copies that already exist.
- **What going private cannot do:** recall copies already made. Anyone who cloned the repo, and public code archives that crawl GitHub, may keep the old content. With 0 forks the exposure is small, and nothing in it gives access to an account.
- **Keeping the website up is the critical part.** The App Store listing's privacy policy and support URLs, and the in-app Watering Protocol link, all point at evapotrack.com. There are two ways to keep it up:
  - **C1. Website in its own public repository (free; recommended).** Create a public repository with only `docs/` (for example `Evapotrack/evapotrack.com`), with Pages on. Move the custom domain to it, check https://evapotrack.com and the privacy page, then make this repository private.
    - DNS at Namecheap doesn't change: the A records are GitHub Pages' shared addresses.
    - HTTPS can take minutes to an hour to re-issue for the new repository. Do it at a quiet time, and verify the domain in GitHub (Settings › Pages › Verified domains, one TXT record at Namecheap) to prevent takeover while it moves.
    - Release-day steps change from "merge into `main`" to "copy `release/1.2`'s `docs/` into the website repository". Runbook F4 and `CLAUDE.md` need that update.
  - **C2. GitHub Pro ($4/month) and flip to private.** Pages keeps publishing from a private repository on Pro. There's nothing to move and the workflow is unchanged, but it costs about $48 a year. Subscribe first and confirm, then change visibility; on the free plan, flipping first takes the site down.

## Decision for the owner: the old `Progress.md` in history

| Option | What it takes | Trade-off |
|---|---|---|
| **A. Leave it (recommended)** | Nothing | The content is low-risk: hours, a fee that is public on the USPTO record, and an order number that can't be used without the account's sign-in. It was already removed from the current files in March |
| B. Rewrite history to purge it | `git filter-repo` on every branch, then force-push all 6 branches. Optionally, ask GitHub Support to purge cached commits | Breaks the "never force-push" rule. Changes every commit hash, so the change log, release history (`c063360`, the planned `v1.0`/`v1.1` tags), and PR #1/#2 references all go stale. Any existing clone or fork keeps the old copy |
| C. Make the repository private | GitHub › Settings › General › Danger Zone › Change visibility | Hides everything, including the full app source code, which is currently public. **GitHub Pages from a private repository needs a paid plan** (GitHub Pro or Team); on the free plan, evapotrack.com would go offline. An alternative is to move `docs/` to a separate public website repository first |

## How to undo

- `.gitignore` changes: `git revert <commit>` (see `engineering/changes/`).
- This document: delete it, or revert its commit.
