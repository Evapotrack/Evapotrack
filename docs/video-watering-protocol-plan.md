# Evapotrack Watering Protocol Video — Production Plan

**Title:** "Evapotrack Watering Protocol — How To"
**Target Length:** 3–5 minutes
**Resolution:** 1920×1080 (16:9)

---

## Production Order

1. **Design & export graphics** (Keynote → PNG)
2. **Screen record** simulator flows (QuickTime)
3. **Edit video** in iMovie (graphics + screen recordings)
4. **Write voiceover script** (timed to the edited cut)
5. **Generate AI voiceover** (using saved voice/tool from previous videos)
6. **Add voiceover to iMovie** timeline, final adjustments
7. **Export & upload** to YouTube (unlisted until launch)

---

## PHASE 1 — Graphics (Keynote)

All graphics: 1920×1080, background `#0f1623` (evBackground), simple line-work style.
Colors: evPrimaryBlue `#5da3f5`, evSecondaryText `#8a95a8`, evSlateGray `#3a4a5c`, evFrostBlue `#a8d4f7`, evWarmOrange `#f5a85d`, evSoftPurple `#b39ddb`, evPrimaryText `#e0e6ed`.

### Graphic 1 — "Empty Pot"
- Line drawing of an empty pot (side profile, cross-section view)
- Pot outline: evSlateGray
- Interior is empty/hollow
- Label below: **"Start with an empty pot"**
- Label color: evPrimaryText, bold, centered

### Graphic 2 — "Fill Pot with Medium"
- Same pot, now filled with a textured pattern (small dots or dashes representing growing medium)
- Medium fill: evFrostBlue dots/lines inside pot
- Pot outline: evSlateGray
- Label: **"Fill with your growing medium"**

### Graphic 3 — "Measure Your Water"
- Measuring container (beaker/pitcher) with water level marked
- Water fill: evPrimaryBlue
- Container outline: evSecondaryText
- Arrow with volume label pointing to water level (e.g., "1.50 L")
- Label: **"Measure your water before pouring"**

### Graphic 4 — "Saturate Slowly & Evenly"
- Container pouring water into the filled pot
- Water stream from container to pot: evPrimaryBlue (dashed/animated-style line)
- Arrows showing even distribution across the top surface
- Medium in pot shown partially saturated (gradient from evFrostBlue at top to dry at bottom)
- Label: **"Water slowly and evenly — aim for runoff"**

### Graphic 5 — "Collect & Measure Runoff"
- Pot sitting on a collection tray/saucer
- Water drops coming out of pot bottom: evWarmOrange
- Tray with collected runoff water: evWarmOrange fill
- Separate measuring container next to tray with runoff poured in, labeled arrow (e.g., "0.25 L")
- Label: **"Collect all runoff, then measure it"**

### Graphic 6 — "Document in Evapotrack"
- Phone outline with simplified app screen
- Screen shows: two field lines labeled "Water Added" and "Runoff Collected" with a checkmark button
- Phone outline: evPrimaryBlue
- Field lines: evFrostBlue
- Checkmark: evPrimaryBlue
- Label: **"Enter your numbers in Evapotrack"**

### Graphic 7 — "Review Your Insights"
- Phone outline with simplified dashboard
- Simple chart line trending, a "Next:" recommendation value, and a capacity % indicator
- Chart line: evPrimaryBlue
- Recommendation indicator: evWarmOrange
- Capacity bar: evSoftPurple
- Label: **"Track progress and follow recommendations"**

### Graphic 8 — "Reference Table Card"
- Text centered on evBackground: **"evapotrack.com/reference"**
- Subtitle below: "Water retention estimates by pot size and medium"
- URL text: evPrimaryBlue, bold, 64pt
- Subtitle: evPrimaryText, regular, 36pt
- Minimal — no illustrations, just the URL and description

### Export
- File → Export To → Images → PNG, 1920×1080
- 8 PNGs total, named: `01-empty-pot.png` through `08-reference.png`

---

## Demo Example — 3-Gallon Fabric Pot with Amended Coco Coir

The demo uses realistic values based on a common indoor setup. This gives viewers real reference numbers without overcomplicating the walkthrough.

**Setup:** 3-gallon fabric pot, 70/30 coco/perlite mix
- Pot volume: ~11.3 liters
- Medium to fill: ~10–11 liters (7–8 L coco + 3–4 L perlite)
- Max water retention (after drainage): ~6.0 L (1.6 gal) for 70/30 mix
- Typical irrigation in flower: 0.75–1.25 gallons (2.8–4.7 L)

**Voiceover context line (during Graphic 2 or Clip B):**
> "In this example, I'm using a 3-gallon fabric pot filled with a 70/30 coco-perlite mix. A pot this size holds about 11 liters of medium, and amended coco in a 3-gallon pot typically retains around 6 liters of water after drainage."

**Demo values used in screen recordings:**

| Field | Clip B (Plant Setup) | Clip C (Watering Log) |
|-------|---------------------|----------------------|
| Plant Name | "Tomato #1" | — |
| Pot Size | "Fabric 3 gal" | — |
| Medium Type | "Coco/perlite 70/30" | — |
| Calculator Water Added | 7.50 L | — |
| Calculator Runoff | 1.50 L | — |
| Max Retention (auto-filled) | 6.00 L | — |
| Goal Runoff % | (blank — 15% default) | — |
| Water Added | — | 4.50 L |
| Runoff Collected | — | 0.65 L |
| Temperature | — | 78 °F |
| Humidity | — | 55% |

*Calculator values represent a saturation test watering (heavy pour to establish capacity). Clip C values represent a normal feeding in flower.*

**Note:** A reference table for common pot sizes, mediums, and expected retention values is published at [evapotrack.com/reference](https://evapotrack.com/reference.html) and linked in the video description.

---

## PHASE 2 — Screen Recording (QuickTime + Xcode Simulator)

Record each flow as a **separate clip**. Use iPhone 17 Pro simulator. Keep recordings tight — no wandering, no idle time. Use the demo values from the table above.

### Clip A — Create a New Grow
1. Start on GrowListView (empty or with existing grows)
2. Tap **+** button
3. CreateGrowView sheet appears
4. Type grow name: **"Indoor Tent 1"**
5. Tap **Save**
6. Checkmark animation plays, sheet dismisses
7. New grow appears in list
- **Duration target:** ~15 seconds

### Clip B — Create a New Plant (with Calculator)
1. Tap into the new grow → PlantListView (empty)
2. Tap **+** button
3. CreatePlantView sheet appears
4. Fill in:
   - Plant Name: **"Tomato #1"**
   - Pot Size: **"Fabric 3 gal"**
   - Medium Type: **"Coco/perlite 70/30"**
5. **Skip** the Max Retention Capacity field (leave it blank for now)
6. Expand the **Calculator** disclosure group
7. Enter Water Added: **"7.50"**
8. Enter Runoff Collected: **"1.50"**
9. Tap **Calculate**
10. Max Retention Capacity auto-fills with **"6.00"**
11. Leave Goal Runoff % blank (show the 15% default hint)
12. Tap **Save**
13. Checkmark animation, sheet dismisses
14. New plant appears in list
- **Duration target:** ~30–40 seconds
- **Key moments to pause on:** Calculator expanding, Calculate button tap, auto-fill result

### Clip C — Add a Watering Log (Following the Protocol)
1. Tap into the new plant → PlantDashboardView
2. Tap **+** button
3. AddWateringLogView sheet appears
4. Fill in:
   - Water Added: **"4.50"** (normal feeding amount for flower stage)
   - Runoff Collected: **"0.65"** (~14% runoff — close to 15% goal)
   - Date/Time: leave as current (default)
   - Temperature: **"78"** (optional, show it being entered)
   - Humidity: **"55"** (optional, show it being entered)
5. Tap **Save**
6. Checkmark animation, sheet dismisses
7. Show the PlantDashboardView with the new log's data reflected in Insights
- **Duration target:** ~25–30 seconds

### Clip D — Review Insights & History (Brief)
1. On PlantDashboardView, show the Insights panel (Next recommendation, Capacity %, Retained average)
2. Tap the chart shortcut button (trailing)
3. HistoryView opens in chart mode
4. Show the chart with the data point
5. Toggle to log list view briefly
- **Duration target:** ~15 seconds

---

## PHASE 3 — iMovie Assembly (Video Edit)

### Timeline Structure

| Timestamp | Content | Source |
|-----------|---------|--------|
| 0:00–0:05 | **Title card**: "Evapotrack Watering Protocol" on evBackground | Keynote PNG |
| 0:05–0:12 | **Graphic 1**: Empty Pot | `01-empty-pot.png` |
| 0:12–0:19 | **Graphic 2**: Fill with Medium | `02-fill-medium.png` |
| 0:19–0:28 | **Graphic 3**: Measure Your Water | `03-measure-water.png` |
| 0:28–0:40 | **Graphic 4**: Saturate Slowly & Evenly | `04-saturate-slowly.png` |
| 0:40–0:52 | **Graphic 5**: Collect & Measure Runoff | `05-collect-runoff.png` |
| 0:52–1:00 | **Graphic 6**: Document in Evapotrack (transition to app) | `06-document.png` |
| 1:00–1:15 | **Clip A**: Create a New Grow | Screen recording |
| 1:15–1:55 | **Clip B**: Create a New Plant + Calculator | Screen recording |
| 1:55–2:25 | **Clip C**: Add a Watering Log | Screen recording |
| 2:25–2:40 | **Clip D**: Review Insights & History | Screen recording |
| 2:40–2:48 | **Graphic 7**: Track Progress | `07-insights.png` |
| 2:48–2:55 | **Reference card**: "evapotrack.com/reference" with table preview graphic | Keynote PNG |
| 2:55–3:05 | **Outro card**: App Store link, "Download Evapotrack", logo | Keynote PNG |

### Edit Notes
- Transitions: 0.5s dissolve between all clips
- Ken Burns: **OFF** (Fit, no zoom) on all graphics
- Trim screen recordings tightly — no dead air, no extra navigation
- Speed up any slow typing if needed (iMovie speed adjustment)

---

## PHASE 4 — Voiceover Script

Write the script **after** the video edit is locked, so timing matches exactly. Script should follow this narrative arc:

### Script Outline (write to exact timings)

**[Title Card]** "Here's how to follow the Evapotrack watering protocol."

**[Graphic 1 — Empty Pot]** "Start with your empty pot."

**[Graphic 2 — Fill Medium]** "Fill it with your growing medium — soil, coco, perlite, whatever you use. In this example, I'm using a 3-gallon fabric pot filled with a 70/30 coco-perlite mix. A pot this size holds about 11 liters of medium, and amended coco in a 3-gallon pot typically retains around 6 liters of water after drainage."

**[Graphic 3 — Measure Water]** "Before you water, measure out your water so you know exactly how much you're adding."

**[Graphic 4 — Saturate]** "Water your medium slowly and evenly, always aiming for runoff. Runoff means water is flowing out the bottom — that's what you want."

**[Graphic 5 — Collect Runoff]** "Collect all the runoff in a tray. Once the pot finishes draining, measure what you collected."

**[Graphic 6 — Document]** "Now you have two numbers — water added and runoff collected. Let's enter them in Evapotrack."

**[Clip A — Create Grow]** "First, create a new grow. This is your growing environment — a tent, a room, a garden bed. Give it a name and save."

**[Clip B — Create Plant + Calculator]** "Next, add a plant. Enter the name, pot size, and medium type. For Max Retention Capacity — that's the most water your medium can absorb before runoff begins. If you don't know it yet, use the built-in calculator. Enter how much water you added and how much runoff you collected during a test watering. Tap Calculate, and it fills in the capacity for you. The Goal Runoff percentage defaults to fifteen percent — that's a good starting point."

**[Clip C — Add Watering Log]** "Now from your plant's dashboard, tap plus to log a watering event. Enter the water you added and the runoff you collected. You can also record temperature and humidity if you want to track those. Tap save."

**[Clip D — Insights]** "Evapotrack calculates your retained volume, capacity percentage, and gives you a recommendation for how much to water next time. The more logs you add, the more accurate it gets."

**[Graphic 7 — Track Progress]** "Follow the protocol every time you water, and Evapotrack handles the math."

**[Outro]** "Check out the water retention reference table at evapotrack.com/reference for common pot sizes and mediums. Download Evapotrack free on the App Store."

---

## PHASE 5 — AI Voiceover Generation

1. Finalize script with exact timings from the edited video
2. Use the same AI voice tool/settings from previous walkthrough videos
3. Generate the full voiceover as a single audio file
4. Export as `.m4a` or `.wav`

---

## PHASE 6 — Final Assembly in iMovie

1. Import the voiceover audio file
2. Drop it onto the timeline, aligned to the video
3. Adjust clip durations if voiceover pacing differs from initial edit
4. Add background music (optional, royalty-free, low volume under voice)
5. Final review — ensure audio/video sync throughout
6. Export: File → Share → File → 1080p, High Quality

---

## PHASE 7 — Upload

1. Upload to YouTube as **unlisted**
2. Title: "Evapotrack Watering Protocol — How To"
3. Description: step-by-step protocol + App Store link + reference table link (evapotrack.com/reference)
4. Tags: same set as existing videos
5. Thumbnail: export Graphic 4 or 6 as the thumbnail (the most visually interesting)
6. Keep unlisted until app launch
