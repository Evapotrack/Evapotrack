# EvapoTrack review and plan (2026-10-06)

**Trigger:** the iPhone auto-updated EvapoTrack to **v1.1 (1)**, and 9 screenshots were taken of the updated app.
**Scope:** why it updated, what is on the device, the full repository history (all branches), the app code, the website, old and new screenshots, and how to preserve past versions.
**Method:**
- Read every branch and its history (132 commits).
- Compared the device screenshots against the simulator screenshots from March.
- Recomputed the on-screen numbers against each branch's algorithm.
- Reused the 2026-09-27 engineering review on `claude/wonderful-edison-i0ukly` instead of repeating it.

**Limits:**
- There is no Mac or Xcode here, so nothing was compiled.
- apps.apple.com and the iTunes lookup API are blocked from this environment, so the release date and live metadata could not be read. Each item that needs App Store Connect or Xcode is marked **[verify]**.

---

## 1. Short answers

**Why did the app update?** iOS installed a newer App Store version automatically. Automatic App Updates install over Wi-Fi, usually while the phone is charging, and the screenshots show the phone charging on Wi-Fi. So an Evapotrack **v1.1 (1)** build is (or was) live on the App Store and replaced the v1.0 (1) that was installed. When v1.1 went live is **[verify]**. Look in App Store Connect › Evapotrack › App Store › version history, or on the iPhone under App Store › your account. Two things to watch:

- Notes from 2026-07-26 (on the matts-hydroponics branch) say "Version 1.0 is live" and that the developer account was locked pending phone re-verification. If v1.1 was released after that, the account is working again. Confirm the account-health checklist from that release plan was done (2FA phone number, membership auto-renew, agreements, certificates).
- If you did **not** knowingly submit or release v1.1 recently, check App Store Connect › Users and Access for unexpected users or API keys.

**What is on the phone?** The v1.1 code from `main` (commit `c063360`, 2026-04-01). It contains none of the newer branch work (no photos, new algorithm or Edit Plant). The evidence is in `engineering/releases/README.md`. The strongest proof is the arithmetic: the dashboard's Next of **1.06 L** = ((0.90 + 0.91)/2) ÷ 0.85, which is the original v1 formula.

**What do the screenshots mean?** v1.1 shipped as planned and works on a real device at a large text size. Two layouts get crowded at that size (section 4). The repository's version number is out of step with what shipped (1.0 vs 1.1).

---

## 2. Timeline (everything that existed before today)

| Date | Event | Commit / branch |
|---|---|---|
| 2026-03-01 | Initial app (grows, plants, logs, dark mode) | `87f5ee3`, `d9c689b` |
| 03-05 → 03-15 | Export, limits, chart and overlays, EN/ES, iPad layout, accessibility, How To | ~50 commits on `main` |
| 03-15 / 03-21 | Light-mode (19) and dark-mode (16) simulator screenshots; copyright notices; first website | `a44443d`, `06adecf`, `8d75508` |
| 03-22 | Second example plant (coco 5 gal), 100% runoff allowed, iPad improvements | `c6d2f13`, `1133b5e`, `70ed803` |
| 03-25 | iPad orientations "for App Store upload"; **v1.0 archived (likely)** | `23611ba` / `fed761b` |
| by 03-29 | **v1.0 live** (App Store link added to the site) | `7ead1f8` |
| 03-29, 04-01 | **v1.1** app changes: protocol link, Dynamic Type polish | `761ff6e`, `c063360` |
| 04-01 → 04-08 | Website: Android badge, paid walkthrough, desk flyer | `62b54c0`…`89cc8c8` (= `main`) |
| 07-26 | Camera-photo feature, ReleasePlan, ProjectStatus (account locked) | `claude/matts-hydroponics-outreach-vwiicq` (3 commits) |
| 09-27 → 09-30 | Engineering review and "Revision 2" (engine, schema, photos via picker, 268 tests) | `claude/wonderful-edison-i0ukly` (15 commits) |
| 10-05 | 3×3 App Store QR sticker | this branch |
| **10-06** | **iPhone auto-updated to v1.1 (1)** | — |

Both unmerged branches start from `89cc8c8`, today's `main`. **Neither has ever been compiled.**

---

## 3. Repository state and risks

| # | Finding | Severity | Detail |
|---|---|---|---|
| R1 | Repo version ≠ shipped version | High | Every branch has `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 1`, but 1.1 (1) shipped. The next archive from the repo would be 1.0 (1) and **App Store Connect would reject it**. Revision 2's docs assumed 1.0 was live; they need 1.1 as the baseline. |
| R2 | No release tags | High | It isn't recorded which commit became 1.0 or 1.1. This is fixed by tags plus `engineering/releases/README.md` (section 6). |
| R3 | Two conflicting photo features | High | matts-hydroponics uses the **camera** (`NSCameraUsageDescription`, image bytes stored in SwiftData with no versioned schema). Revision 2 uses **PhotosPicker**: no permission prompt, files on disk, versioned schema with a migration test, and a stated "no camera" rule. They cannot both merge. |
| R4 | 268 + ~15 tests never run | High | Both branches were written without Xcode. Expect compile fixes. |
| R5 | Migration baseline must be the **v1.1** store | Medium | Revision 2 freezes `SchemaV1` from models last changed on 2026-03-21. `c063360` doesn't touch models, so v1.1's store matches V1. Still capture a real v1.1 store for the skipped migration test **[verify]**. |
| R6 | `screenshots/` is gitignored but 35 files are tracked | Low | Old files stay tracked; new ones need `git add -f`. The v1.1 device set is in `engineering/releases/v1.1/device-screenshots/` instead (EXIF/XMP removed). |
| R7 | Internal docs are published on the website | Low | `docs/*.md` (Specification, DataModel, …) are served on evapotrack.com and are out of date. Revision 2 moves them to `engineering/app-docs/`. |

## 4. App: what the v1.1 device screenshots show

Old (simulator, iPhone 17 Pro, v1.0, default text) vs new (real iPhone, 1170×2532, v1.1, larger text, apparently with Bold Text on):

| Screen | Changed between old and new | Cause |
|---|---|---|
| Settings | Footer v1.0 (1) → **v1.1 (1)**; units L instead of gal | The update; your preference |
| My Grows | 1 plant → **2 plants**, date Mar 29 | Second example plant (`c6d2f13`) |
| Plant list | Example Plant 2 added | Same |
| How To | Same 6 topics; heavier, larger type | Device text settings (the rounded font and two-tone titles were already in v1.0) |
| Dashboard, History, Chart | Same values in liters; layout holds at large text | v1.1 Dynamic Type work |

Problems seen on the device (at a **large but non-accessibility** text size; the v1.1 fixes only start at accessibility sizes):

| ID | Problem | Suggested fix |
|---|---|---|
| UI-1 | Plant Info: "Max Capacity" and "Goal Runoff" wrap to 2 lines while "Pot" and "Medium" don't, so the values sit at uneven heights | Align the 4 columns on the top edge and reserve 2 lines for every label, or switch to a 2×2 grid from `.xxLarge` |
| UI-2 | Insights: "Goal (15.0%)" fills its tile edge to edge; Spanish "Obj." labels or a 2-digit goal will truncate | Drop the Insights grid to 2 columns (or put the % on its own line) from `.xxLarge`, not only at accessibility sizes |
| UI-3 | History rows: "ret" is an unclear abbreviation | Use "retained" ("retenido") and move the % under it at large sizes |
| UI-4 | Example data Max Capacity 1.60 L contradicts the website reference table (3 gal soil ≈ 4.5 L) | Already fixed in revision 2 (MRC-1: one definition, example values 1.5 / 2.3 L) |

Code findings from the 2026-09-27 review that still apply to the shipped v1.1 (full text on the revision-2 branch, `engineering/reviews/`):
- **The Next recommendation lags a growing plant** (ALG-1/2), and **100% runoff hides insights** (ALG-3).
- **"1,5" is rejected** in comma-decimal regions (LOC-1). This hits the Spanish audience.
- **Max Retention Capacity has three definitions**, plants can't be edited, and the 105% hard block (MRC-1/2) can stop valid logs.
- **No versioned schema, no rollback after a failed save** (DATA-1/2).
- **3-second launch screen on every launch** (UX-1, a product decision).

Revision 2 addresses all of these except UX-1.

## 5. Website (`docs/`, evapotrack.com)

Still true on `main` today:
- **Android stated as fact** in `index.html:323-331`, `privacy-policy.html:60,66` ("Room database") and `support.html:89` ("Android 8.0"). No Android app exists. This is the most important correction because the privacy and support pages are what App Review reads (WEB-1).
- "Saturation levels" wording (WEB-2); a YouTube embed loads Google tracking (WEB-3); internal `.md` docs are published (WEB-5); no robots.txt or sitemap (WEB-6).
- The 5 carousel screenshots are v1.0 simulator captures in gallons with 1 example plant. They still match the UI, but should be re-shot once revision 2 ships, because they would then show the old Max Capacity and the old Insights.

Revision 2 already fixes all of these, but holds them back until the photo release goes live. **The Android corrections don't depend on photos.** Take those to `main` now (step P1.3).

## 6. Preserving past versions

**Recommendation: tags plus a release record, not copied source folders.**

- **Copying source into the repo is not recommended.** A folder like `releases/v1.0/Evapotrack/` duplicates every Swift file. Search results and reviews would hit both copies. It could also end up inside Xcode's file-system-synchronized groups and drift from history. None of that adds anything over git, which already holds every version byte for byte.
- **Annotated git tags** (`v1.0`, `v1.1`, then one per release) pin the exact source. `git checkout v1.1`, `git archive v1.1` or GitHub's tag page give anyone the full historical build. Tags can't change by accident and cost nothing.
- **`engineering/releases/README.md`** (added) is the human-readable record: version, build, commit, confidence, what changed, and evidence. `engineering/releases/<version>/` holds that release's screenshots. The v1.1 device set is already there.
- Optional: a **GitHub Release** per tag, with the notes and the screenshots attached. It's a downloadable page, still backed by the same tag.
- From now on, commit the version bump before archiving and tag the exact archived commit (checklist in the release record).

Safety: tags and this folder only add files; nothing existing is rewritten. `engineering/` is outside `docs/`, so the website doesn't publish it, but the repo is public. Never put credentials, revenue figures or account details here (keep those in the gitignored `private/`).

---

## 7. Plan

Each step says who can do it: **Mac** = you in Xcode or App Store Connect; **Cloud** = a Claude session like this one.

### Phase 0: Establish the facts (this week)
- [ ] **0.1 (Mac)** App Store Connect: note v1.1's release date and whether v1.0 → v1.1 was phased. Check Users and Access and Agreements, and that membership auto-renews.
- [ ] **0.2 (Mac)** Xcode Organizer: note the archive time of v1.0 and v1.1. Send them over to finalize the tag commits.
- [ ] **0.3 (Cloud, after 0.2)** Create and push the annotated tags `v1.0` and `v1.1` (needs your OK to push tags).
- [ ] **0.4 (Cloud)** Commit `MARKETING_VERSION = 1.1` on `main` (R1). The next release becomes 1.2 (or 1.1.1 for a hotfix).

### Phase 1: Quick, safe wins on `main` (no app risk)
- [ ] **1.1 (Cloud)** Merge this branch: the sticker, the release record and this plan.
- [ ] **1.2 (Mac)** Print the alignment test page of the sticker, then the sheet.
- [ ] **1.3 (Cloud)** Website: correct the Android claims (index, privacy, support). Fix "saturation" and the YouTube nocookie embed. Add robots.txt and sitemap. Move `docs/*.md` out of the published folder. Cherry-pick these from revision 2's commit `4d3dc6b`, leaving out the photo text.

### Phase 2: Choose the next release (decision D1)
- [ ] **2.1 (You)** Pick the photo approach. **Recommended: revision 2 (PhotosPicker)**:
  - no permission prompt;
  - keeps the "local, simple" promise;
  - versioned schema and migration;
  - far more tests;
  - it also contains the algorithm, locale and MRC fixes.

  Keep matts-hydroponics' `ReleasePlan.md`/`ProjectStatus.md` (merge their useful content into `engineering/`) and retire its camera code. If you want camera capture as well, add it later on top of revision 2's photo store.
- [ ] **2.2 (Cloud)** Rebase or merge revision 2 onto `main` after Phase 1. Set the version to 1.2 (1), and update its docs from "1.0 live" to "1.1 live".

### Phase 3: Make revision 2 real (needs the Mac)
- [ ] **3.1** Build in Xcode; fix compile errors. Send them over and a cloud session can patch them.
- [ ] **3.2** Run all tests; fix failures. Capture a real **v1.1** store for the skipped migration test.
- [ ] **3.3** Device checklist (revision 2 report §9). The most important item is to **install the 1.2 build over the App Store v1.1 on this iPhone** and confirm the Example Grow and all logs survive.
- [ ] **3.4** Fix UI-1/UI-2/UI-3 at your current text size (they apply to both layouts).
- [ ] **3.5** Decide UX-1 (launch delay) and the new blue (#2F6DBD).

### Phase 4: Release 1.2
- [ ] **4.1** Archive the **committed and tagged** 1.2 commit; use TestFlight on this iPhone; submit with a phased release. Review notes: "photos chosen by the user, stored on device only".
- [ ] **4.2** Publish the website and privacy-policy photo text the same day. Re-shoot the 5 carousel screenshots on 1.2.
- [ ] **4.3** Tag `v1.2`; add the entry and screenshots to `engineering/releases/`.

### Decisions needed from you
- **D1:** which photo approach (recommendation: revision 2's PhotosPicker).
- **D2:** OK to push the release tags once 0.2 confirms the commits.
- **D3:** keep the old simulator screenshot sets in `screenshots/` (tracked, despite the ignore rule) or move them under `engineering/releases/v1.0/`.
