# EvapoTrack App Store compliance: iPhone and iPad (2026-10-06)

This is checked against the project settings on `main` (live v1.1) and on revision 2 (the planned 1.2), and against Apple's current requirements. Apple's own pages were not reachable from this environment, so the requirements come from search results citing them. Each one is linked under Sources. Items marked **[verify]** need App Store Connect or Xcode.

## Summary

| # | Requirement | v1.1 (live) | 1.2 (revision 2) | Action |
|---|---|---|---|---|
| 1 | **Build with Xcode 26 / iOS 26 SDK** (all uploads since 2026-04-28) | Project created with Xcode 26.2 | Same | Archive with Xcode 26.x, which needs macOS Sequoia 15.6 or later **[verify]** |
| 2 | **Updated age-rating questionnaire** (new 13+/16+/18+ ratings; updates are blocked until answered; deadline was 2026-01-31) | Unknown | — | App Store Connect › App Information › Age Rating: confirm it's answered. Nothing in the app references drugs, alcohol, violence or medical topics, so expect the lowest rating **[verify]** |
| 3 | **EU trader status** (Digital Services Act; apps without a status were removed from EU storefronts from 2025-02-17) | Unknown | — | App Store Connect › Business: confirm a trader or non-trader status is set **[verify]** |
| 4 | **Privacy manifest** (required-reason APIs) | ✅ Declares UserDefaults (CA92.1); no tracking; no collected data | ✅ Unchanged. The photo code reads file sizes, which are not a required-reason API, and avoids file-timestamp and disk-space APIs | None |
| 5 | **App Privacy label** | "Data Not Collected" (no network code, no SDKs) | ✅ Still accurate: photos never leave the device | Re-confirm the questionnaire at submission |
| 6 | **Permission prompts and purpose strings** | None used | ✅ None; the photo picker needs no permission | 1.3 camera: add `NSCameraUsageDescription` in EN and ES, asked only on first tap |
| 7 | **Export compliance** | ✅ `ITSAppUsesNonExemptEncryption = NO` | ✅ Same | None |
| 8 | **iPhone orientation** | Portrait only (allowed for iPhone) | Same | None |
| 9 | **iPad: universal app, all orientations** | ✅ Device family iPhone + iPad; all 4 iPad orientations declared; no code locks orientation | ✅ Same | Note: the 2026-03-25 commit message saying the app "locks to portrait at runtime" is wrong. Nothing locks it, and that's correct for iPad |
| 10 | **iPadOS 26 windowing** (`UIRequiresFullScreen` deprecated; apps must handle freely resized windows) | ✅ Not used; layouts adapt via size classes | Same | **Test** 1.2 in iPadOS 26 windowed mode at narrow and wide sizes, in landscape, and in split layouts (runbook E5) |
| 11 | **Minimum iOS 17** | iOS 17.0 | iOS 17.0; adds a SwiftData versioned schema | **Test the upgrade on an iOS 17 simulator** as well as iOS 26. SwiftData's migration behavior changed between OS versions, and iOS 17 is the riskiest |
| 12 | **Screenshots** (6.9-inch iPhone and 13-inch iPad are the required base sizes; others scale) | Existing set carries over | The UI changes (Insights, blue, photos) | Refresh both sizes with 1.2. iPad screenshots must show the iPad layout, not a stretched iPhone image |
| 13 | **Accurate metadata** (guideline 2.3) | Website claims Android | Website fixed (runbook C1) | Also check the **App Store description and keywords**, which are kept in `private/` (not in the repo), for Android, "interactive charts" or "saturation" wording **[verify]** |
| 14 | **Privacy policy and support URLs** (guideline 5.1.1) | ✅ Present; Android wording to fix | Photo section published on release day | Runbook C1, then F4 |
| 15 | **Launch screen** | ✅ Generated (`UILaunchScreen`) | Same | The extra 3 s animated intro is allowed, but slow. See decision A6 |
| 16 | **Localization** | In-app EN/ES; Spanish not declared to iOS | ✅ Declares `es` (system screens appear in Spanish) | Optional: add a Spanish App Store listing |
| 17 | **Accessibility Nutrition Labels** (optional declarations in App Store Connect) | Not declared | After 1.2: VoiceOver, Larger Text, Dark Interface, Sufficient Contrast (with the new blue) are all supportable | Optional: declare them after the device checklist confirms each |
| 18 | **Mac (Apple silicon) and Vision Pro availability** of the iPad app | Unknown | — | App Store Connect › Pricing and Availability: keep it only if it has been tried there, otherwise opt out **[verify]** |

## Cannabis and guideline 1.4.3

Guideline 1.4.3 forbids apps that **encourage consumption** of illegal drugs, and apps that **facilitate the sale** of marijuana except through licensed dispensaries, which must be geo-restricted. A watering tracker does neither.

- **Today:** EvapoTrack's app, website and store text say "plants", "coco", "soil" and "hydroponics", never cannabis (checked across `Evapotrack/`, `docs/` and revision 2).
- **Recommendation:** keep the **app, screenshots and store listing plant-generic**.
  - The cannabis test data in `engineering/research/cannabis-dtw/` is for testing only. It must not ship in the app (for example as example data) or appear in store screenshots.
  - Referencing cannabis in the app would change the age-rating answers (drug references) and invite a stricter review, for no product benefit.
- **Marketing** to cannabis growers outside the App Store (grow shops, forums) doesn't change the app's review status. Keep claims accurate (iPhone and iPad; Android only "coming soon").

## Where these checks live in the runbook

| Runbook step | Adds |
|---|---|
| A1 (App Store Connect review) | Items 2, 3, 13 and 18 |
| E1 (build) | Item 1 |
| E5 (device checklist) | Items 10 and 11: iPadOS 26 windowing, and the upgrade on an iOS 17 simulator |
| F3 (submission) | Items 5, 12 and 17 |

## Sources

- [Apple: SDK minimum requirements](https://developer.apple.com/news/upcoming-requirements/) and [Expo: App Store Connect minimum SDK 26](https://expo.dev/blog/app-store-connect-minimum-sdk-26)
- [Apple TN3192: migrating from the deprecated UIRequiresFullScreen key](https://developer.apple.com/tutorials/data/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key.md)
- [9to5Mac / iGeeksBlog: new App Store age ratings and the January 31, 2026 deadline](https://www.igeeksblog.com/apple-app-store-age-ratings/)
- [GSMArena: Apple suspends 135,000+ apps in the EU over trader status](https://www.gsmarena.com/apple_suspends_over_135000_apps_across_eu_app_stores-news-66619.php) and [Median: updating trader status](https://median.co/blog/how-to-update-apple-trader-status-app-store-connect)
- [App Store Connect Help: screenshot specifications](https://developer-mdn.apple.com/help/app-store-connect/reference/screenshot-specifications) and [ASO.dev 2026 screenshot guide](https://aso.dev/app-store-connect/screenshots/)
- [Cannabis Science and Technology: Apple's guideline change on legal cannabis sale and delivery](https://www.cannabissciencetech.com/view/apple-quietly-changes-app-store-guidelines-regarding-legal-cannabis-sale-and-delivery)
