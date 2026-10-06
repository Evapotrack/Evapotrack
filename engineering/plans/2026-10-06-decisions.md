# EvapoTrack: recommended decisions for approval (2026-10-06)

This document turns the reviews into one recommended set of decisions. It judges each option against what the app is for and how it is used in practice. Section 5 is a final review of the set as a whole. Approve, change or reject each item in section 6.

Companion documents:
- [`2026-10-06-review-and-plan.md`](2026-10-06-review-and-plan.md): what exists and what the screenshots mean.
- [`2026-10-06-runbook.md`](2026-10-06-runbook.md): how to carry out each step safely.

---

## 1. The lens: what EvapoTrack is for

Every decision below is judged against these facts.

- **Purpose.** It helps drain-to-waste and soil growers water the right amount. It does that from the grower's own measurements (water added, runoff collected, retained water), not from guesses.
- **The protocol it teaches.** Get runoff every watering, aiming for the goal % (15% by default). That means **too little water is the costly mistake**:
  - No runoff means dry spots and salt build-up in the medium.
  - A little extra runoff mostly costs some water and nutrient solution, because the excess drains away. Frequency, not volume, is what keeps a pot too wet.
- **Product principles.** It works offline, keeps data on the device, has no account, no cloud and no tracking, and stays simple. It is bilingual (EN/ES).
- **Real-world use.** The grower stands at the plant with a measuring jug and wet hands, logs right after watering, opens the app several times a day, and may use large text. Spanish-region phones type decimal commas (1,5).

## 2. New evidence gathered for this decision

1. **Revision 2's engine on your own data.** Your Example Plant's Next changes from **1.06 L** (v1.1) to **0.92 L**:
   - The last watering retained 0.90 L at 10% runoff. The new engine smooths through the earlier decline (1.31 → 0.68 L) and partly discounts the rebound.
   - Following 0.92 L would give about 2% runoff for one watering. Because that watering still has runoff, it is an exact measurement, so the engine corrects itself within 2–3 waterings.
   - Existing users **will see their Next number change after updating**.
2. **One possible tuning, tested.** "Asymmetric response" (`a_up`) lets a watering that retained **more** than expected move the estimate faster than one that retained less. That matches the protocol's cost asymmetry. Same simulation as revision 2's study (18 scenarios × 200 runs); script and output in `engineering/research/algorithm/2026-10-06-asymmetric-check/`:

   | Model | Zero runoff | Under goal | Over 20% runoff | >2× goal | Avg error | Your Example Plant |
   |---|---|---|---|---|---|---|
   | v1.1 (live) | 34.4% | 50.3% | 16.4% | 7.2% | 9.9 pp | 1.06 L |
   | **Revision 2** | **9.7%** | **27.8%** | **15.4%** | **4.5%** | **6.2 pp** | **0.92 L** |
   | `a_up` 0.6 | 9.1% | 25.9% | 16.4% | 4.6% | 6.1 pp | 0.95 L |
   | `a_up` 0.7 | 8.7% | 24.1% | 17.4% | 4.8% | 6.1 pp | 0.97 L |

   Revision 2 reproduces its published results exactly. The tuning is a small trade (fewer under-goal waterings for more over-goal ones), not a clear win.
3. **A weakness both versions share.** When demand depends on time and the grower waters at irregular 1–3 day intervals (scenario S8), **both** models give zero runoff on 44–50% of waterings. Growers who water "when the pot is dry", or on a regular schedule, are not affected (S8b: about 0%).
4. **Readability of the blue.** Measured contrast for text:

   | Color | Contrast | Guideline |
   |---|---|---|
   | Current light-mode blue, on white | 3.29:1 | Fails 4.5:1 |
   | Current light-mode blue, on Day mode's dimmed background | 2.95:1 | Fails |
   | Revision 2's blue | 5.19:1 | Passes |
   | White text on the current dark-mode blue buttons | 2.62:1 | Revision 2 fixes this with a dedicated "on blue" text color |
5. **The photo workflow.** Revision 2 attaches a photo only while creating a watering log, through the system photo picker, which has no camera button. At the plant, that means taking the photo in the Camera app first, then picking it.
6. **Text-size crowding.** Revision 2 still changes layout only at the accessibility text sizes. The crowding seen on your phone (Plant Info row, Insights tiles, "ret") would carry into 1.2 unless fixed.

---

## 3. Decisions, one by one

Confidence: **High** = clear on evidence; **Medium** = judgment call with good reasons; **Yours** = a taste or product call.

### A. Product and app

**A1. Photos: the photo picker in 1.2; the camera and "add a photo later" in 1.3.** Confidence: High.
- **Why the picker now:**
  - It asks for no permission and keeps EXIF/GPS out of saved photos (tested).
  - It stores files with a versioned upgrade checked against the shipped database (23 of 23 fields).
  - It is already built along with every other fix.
- **Why the camera branch loses:**
  - It conflicts with revision 2 in 8 files, so choosing it means dropping or redoing the algorithm, decimal-comma and Edit Plant fixes.
  - It changes stored data with no tested upgrade.
- **The real-world gap:** at the plant, using the picker means a trip to the Camera app first. Version 1.3 closes the gap two ways:
  - A **Take Photo** button, which asks for camera permission only when first tapped.
  - **Add or replace a photo on an existing log**, so a grower can log the watering at the plant and attach a photo later.

  Photos aren't measurements, so allowing this doesn't weaken the "logs can't be edited" rule for data.

**A2. Release scope: one 1.2 with revision 2 plus three small, isolated items.** Confidence: Medium-High.
- **Why one release:** revision 2 is interwoven. The new data version contains the photo field, and the website text mixes them. Splitting it would mean new, untested engineering and two data upgrades.
- **The three additions** (A5, A6, A7) are small and UI-only.
- **Sequencing:** they are done only **after** revision 2 compiles and its tests pass, so the first build tests revision 2 exactly as written.

**A3. Recommendation engine: revision 2's as built (`a_up` 0.5) in 1.2; consider 0.6–0.7 in 1.3 with real data.** Confidence: Medium-High.
- **Why ship it:** the big gain is v1.1 → revision 2 (zero runoff 34% → 10%; recovery from a bad watering in 5 waterings instead of 14–30; still works after a flush; explains itself).
- **Why not tune it now:** `a_up` would move a further 1–4 points from under-goal to over-goal, a preference shift rather than a clear improvement. Changing it would also alter the expected values of about 30 tests before their first run, mixing a tuning change into the first compile.
- **When to revisit:** after a few weeks of real 1.2 logs. If growers' plants rebound often (as in your Example Plant), adopt 0.6–0.7 with a fresh simulation.
- **Required alongside:** the release notes must say that Next changes after updating (draft in §4). Revision 2's Insights already show the basis ("based on recent retained water of X…").

**A4. Goal runoff limited to 5–50%.** Confidence: Medium.
- **Why:** below 5% means aiming for almost no runoff, which the protocol says to avoid; with normal measurement noise, many waterings would end with none. Plants saved with values outside the range are kept and clamped, with a visible note. No stored data changes.
- **Cost:** soil growers who deliberately aim for minimal runoff may find 5% the floor.
- **Recommendation:** accept.

**A5. Fix the text-size crowding.** Confidence: High.
- **What:**
  - The Plant Info row becomes a 2×2 grid from the `xxLarge` text size.
  - The Insights tiles put the percentage on its own line (or use 1 column) from `xxLarge`.
  - History rows show "retained" / "retenido" instead of "ret".
- **Why:** you use a large text size, and so do many growers. These are layout-only edits, one view each, EN and ES together.

**A6. Launch screen: about 1.5 seconds instead of about 3.3.** Confidence: Yours (recommendation: 1.5 s).
- **What it does today:** it appears on every cold launch and runs a timed animation, about 3.3 s in total:
  - the icon and name fade in (0–0.8 s);
  - the slogan "Optimize plant watering" fades in (0.6–1.2 s);
  - everything holds, then fades out (2.2–2.7 s);
  - the app appears at 3.0 s, plus a 0.3 s cross-fade.
- **Why shorten it:** the app is opened often, at the plant.
- **What changes:** compress the whole sequence:
  - the icon and name fade in over 0.4 s;
  - the slogan fades in from 0.2 s to 0.5 s;
  - everything holds until 1.1 s, then fades out over 0.3 s;
  - the app appears at 1.5 s.

  Every element still shows, and the slogan stays fully visible for about 0.6 s. That is a handful of numbers in `LaunchView.swift` and `EvapotrackApp.swift`.
- *Final-review correction:* the first draft said "change 3 s to 1 s". That would have cut the app in at 1 s, before the slogan had finished fading in.
- **Alternative:** show it on first launch only. That's faster still, but daily users lose the brand moment.

**A7. Watering guidance for the shared weakness.** Confidence: High.
- **What:** add one sentence to How To › "What Is Next?" and to the website protocol: *"Next works best when you water at a consistent dryness (lift the pot) or on a regular schedule."*
- **Why:** it costs nothing, and it steers growers away from the one pattern (S8) where both models struggle.

**A8. Light-mode blue #2F6DBD.** Confidence: High on readability; Yours on looks.
- **Why:** it raises text contrast from 3.29:1 to 5.19:1 (2.95:1 → 4.65:1 on Day mode's background). Dark mode, which you use, doesn't change except for the white-on-blue button fix.
- **Cost:** a slight light-mode look change, and the light-mode screenshots would be refreshed with 1.2.

### B. Repository, website and release process

| # | Decision | Confidence | One-line reason |
|---|---|---|---|
| B1 | Fix the website now, without photo text (runbook C1/C2) | High | False Android claims sit on the pages App Review reads; one rehearsed conflict later |
| B2 | Use a `release/1.2` branch; reach `main` on release day | High | `main`'s `docs/` folder is the live site; the app and site change in the same hour |
| B3 | Merge revision 2, don't rebase it | High | Keeps its pushed history and the commit references in its reports valid |
| B4 | Tags `v1.0`/`v1.1` plus the release record; GitHub Releases optional | High | Exact, permanent, no duplicate code |
| B5 | Version 1.2, build 1 | High | Above the live 1.1 (1); never reuse a version + build pair |
| B6 | Full testing before release (tests, real v1.1 database, simulator rehearsal, TestFlight over the App Store build) | High | First release that changes stored data; App Store versions can't be rolled back |
| B7 | Manual release plus phased rollout | High | Lets the app and site switch together; you can pause if crashes appear |
| B8 | Pull requests for anything touching the app or `docs/` | High | Review before the site changes; one-click undo |
| B9 | Camera branch: don't merge; tag `archive/camera-photos-2026-07` | High | Kept as history; its camera screen can inform 1.3's Take Photo |
| B10 | Mac snapshot: push the project file and recognized source only; zip the rest privately | High | Keeps the exact v1.1 state without risking anything private in a public repo |

---

## 4. The recommended package

**Version 1.2** (built in this order):
1. Revision 2 as written. Compile, run all 268 tests, add the real v1.1 database fixture, and rehearse the upgrade.
2. Then A5 (text-size fixes), A6 (launch about 1.5 s), A7 (guidance sentence), each its own commit, EN and ES.
3. Then the full device checklist, TestFlight, submission.

**Draft release notes**

EN:
> **Smarter Next.** Recommendations now follow how much your plant has been drinking recently, react to growth, and explain how they were calculated. Your Next amount may change after this update.
> **Optional photos.** Add a photo to a new watering and view it full screen. Photos stay on your device.
> **Edit Plant.** Correct the pot, medium, capacity or goal runoff.
> Decimal commas (1,5) now work, and the app is easier to read in Day mode and at large text sizes.

ES:
> **Siguiente más inteligente.** Las recomendaciones ahora siguen cuánta agua ha retenido tu planta recientemente, reaccionan al crecimiento y explican cómo se calcularon. Tu cantidad Siguiente puede cambiar tras esta actualización.
> **Fotos opcionales.** Añade una foto a un riego nuevo y mírala a pantalla completa. Las fotos se quedan en tu dispositivo.
> **Editar Planta.** Corrige la maceta, el sustrato, la capacidad o el drenaje objetivo.
> Ya funcionan los decimales con coma (1,5), y la app es más fácil de leer en modo Día y con texto grande.

**Version 1.3** (after 1.2 is stable), in order of real-world value:
1. Take Photo (camera, permission asked on first tap).
2. Add or replace a photo on an existing log.
3. Engine tuning (`a_up` 0.6–0.7), only if real 1.2 logs support it.
4. Correcting a mistyped log (today: delete and re-enter).
5. Import or restore from an export.

---

## 5. Final review of this package

Each check was run against the whole set, not item by item.

| # | Check | Result |
|---|---|---|
| 1 | Fits the product principles (offline, on-device, no account, simple) | ✅ 1.2 adds no permission, network or service. The camera is deferred to 1.3, and its permission is asked only on use |
| 2 | Protects existing users' data | ✅ The upgrade baseline matches the shipped database (23/23). The upgrade is tested 3 ways before release. Revision 2 shows an error screen instead of ever replacing a database it can't open |
| 3 | No change hides another's failure | ⚠️→✅ **Found:** adding A5–A7 to the first build would mix their errors with revision 2's. **Resolved:** A5–A7 come only after revision 2 is green (§4, step 2) |
| 4 | Users understand a changed number | ⚠️→✅ **Found:** Next changes on update (your Example Plant: 1.06 → 0.92 L). **Resolved:** release-note sentence (§4) plus revision 2's on-screen explanation |
| 5 | Known algorithm weaknesses are addressed or disclosed | ⚠️→✅ **Found:** both models struggle with irregular, time-driven watering (S8). **Resolved:** A7 guidance now; real-data research listed for later |
| 6 | App Review readiness | ✅ No new Info.plist permission keys in 1.2. During review, the live privacy policy stays true ("all data is stored locally"); its photo section publishes on release day |
| 7 | Spanish parity | ✅ Every new string (A5–A7, release notes) is specified in EN and ES |
| 8 | Backups and exports | ✅ Photos are included in device backups but not in the text export; the support FAQ (published on release day) says so. Settings shows photo storage use (about 0.45 MB per photo) |
| 9 | Website and app stay consistent | ✅ The photo-free fixes go now; photo text goes on release day; carousel screenshots are refreshed after 1.2 |
| 10 | Every step can be undone | ✅ Website: one revert. Branches: disposable until release. Tags: removable before use. Live app: phased-release pause, then 1.2.1 |
| 11 | Effort is proportionate | ✅ The heavy work is the necessary compile, test and device testing. The A5–A7 additions are about a day's work |
| 12 | Anything left that needs a person | Account checks, Organizer times, Xcode builds, device testing, App Store submission, and the "Yours" calls (A6, A8 look) |
| 13 | Every factual claim in this document re-checked against code | ⚠️→✅ **Found:** A6's "one-line change" was wrong, because the launch animation is timed to the 3 s wait. **Resolved:** A6 re-times the whole sequence. Confirmed: neither `main` nor revision 2 declares any permission keys; the Spanish terms in the notes match the app ("Siguiente", "Editar Planta", "Día"); revision 2 keeps the 3 s launch, so A6 applies on top of it |

**Residual risks:**
- **Compile surprises.** Revision 2 has never been compiled. Mitigation: the build-and-fix loop (runbook E1–E2).
- **Real growers may differ from the simulation.** Mitigation: the 1.3 review of real logs before any tuning.
- **Picker friction until 1.3.** Photos are optional, so logging is never blocked.

---

## 6. Approval checklist

Reply with the item numbers you approve (for example "approve all", or "approve all except A6: first launch only").

- [ ] **A1** Photo picker in 1.2; Take Photo and "add a photo later" in 1.3
- [ ] **A2** One 1.2 release: revision 2 plus A5–A7, added after it compiles and passes its tests
- [ ] **A3** Revision 2's engine as built; revisit tuning with real data in 1.3
- [ ] **A4** Goal runoff 5–50%
- [ ] **A5** Text-size crowding fixes
- [ ] **A6** Launch screen about 1.5 s with the animation re-timed (or: first launch only / keep it as is)
- [ ] **A7** Watering-consistency guidance sentence
- [ ] **A8** New light-mode blue
- [ ] **B1–B10** Repository, website and release process as in the table
- [ ] **Release notes** as drafted (or with your edits)
