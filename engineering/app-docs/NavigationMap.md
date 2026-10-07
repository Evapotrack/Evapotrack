# Evapotrack - Navigation Map

> Internal document. Moved out of the public website folder (`docs/`) on 2026-09-28 and updated for the next revision.

## Navigation Hierarchy

```
GrowListView (ROOT - owns NavigationStack)
│
├── [Push] PlantListView(grow:)
│   │   via navigationDestination(for: GrowNavID.self)
│   │
│   ├── [Push] PlantDashboardView(plant:)
│   │   │   via navigationDestination(for: PlantNavID.self)
│   │   │
│   │   ├── [Push] HistoryView(vm:waterUnit:)
│   │   │   │   via NavigationLink in HistoryPanelView or chart toolbar button
│   │   │   │
│   │   │   ├── [Sheet] AddWateringLogView(plant:)
│   │   │   │       via HistoryView's own isShowingAddWatering
│   │   │   │
│   │   │   ├── [FullScreenCover] PhotoViewer(item:)
│   │   │   │       via a log's photo thumbnail or "View photo" action
│   │   │   │
│   │   │   └── [Push] HowToView(context: .chart)
│   │   │           via NavigationLink in toolbar
│   │   │
│   │   ├── [Push] HowToView(context: .addWatering)
│   │   │       via NavigationLink in toolbar
│   │   │
│   │   ├── [Sheet] AddWateringLogView(plant:)
│   │   │       via vm.isShowingAddWatering
│   │   │   └── [FullScreenCover] PhotoViewer(item:)  (preview of the picked photo)
│   │   │
│   │   ├── [Sheet] PlantFormView(mode: .edit(plant))
│   │   │       via Edit button in Plant Info header
│   │   │
│   │   └── [Sheet] SettingsView()
│   │           via isShowingSettings
│   │
│   ├── [Push] HowToView(context: .general)
│   │       via NavigationLink in toolbar
│   │
│   ├── [Sheet] PlantFormView(mode: .create(grow))
│   │       via isShowingCreatePlant
│   │
│   └── [Sheet] SettingsView()
│           via isShowingSettings
│
├── [Push] HowToView(context: .general)
│       via NavigationLink in toolbar
│
├── [Sheet] CreateGrowView()
│       via isShowingCreateGrow
│
└── [Sheet] SettingsView()
        via isShowingSettings
```

## Navigation Patterns

### Push Navigation
- Uses typed wrapper structs (`GrowNavID`, `PlantNavID`) to avoid UUID collision in `navigationDestination`.
- GrowListView registers `navigationDestination(for: GrowNavID.self)`.
- PlantListView registers `navigationDestination(for: PlantNavID.self)`.
- Both include fallback `ContentUnavailableView` if entity not found.

### Sheet Navigation
- All sheets wrap content in `NavigationStack` for toolbar support.
- All sheets apply `.preferredColorScheme(settingsVM.colorScheme)`.
- Create/Add sheets dismiss after 1-second save confirmation animation.
- Settings sheet provides unit/theme pickers with auto-save.

### Toolbar Layout (consistent across list views)

| Placement | Item | Action |
|-----------|------|--------|
| Leading | Back chevron | Pops view (child views only) |
| Leading | Gear icon | Opens Settings sheet |
| Leading | Question mark icon | Pushes HowToView |
| Primary Action | Trash + Plus (grouped) | Delete selected / Create new |

PlantDashboardView adds a chart button (trailing) that pushes HistoryView in chart mode.
HistoryView adds a chart/list toggle (trailing) and help button (leading).

### Delete Flow
1. User taps selection circle on an item.
2. Trash button becomes red and enabled.
3. User taps trash.
4. Custom `DeleteConfirmationView` overlay appears with Cancel/Delete.
5. On confirm: entity deleted, selection cleared, overlay dismissed.

### Back Navigation
- Standard iOS back button in navigation bar.
- Selection state resets on `.onAppear` when returning to list views.

## Screen Summary

| Screen | Type | Title Style | Has Toolbar |
|--------|------|-------------|-------------|
| GrowListView | Root | Large ("My Grows") | Yes |
| PlantListView | Push | Large (grow name) | Yes |
| PlantDashboardView | Push | Inline (empty) + centered name | Yes |
| HistoryView | Push | Inline (empty) | Yes (help, chart toggle, trash+plus) |
| CreateGrowView | Sheet | Inline ("Add Grow") | Cancel + Save |
| PlantFormView | Sheet | Inline ("Add Plant" / "Edit Plant") | Cancel + Save |
| PhotoViewer | Full-screen cover | None | Close (X) |
| AddWateringLogView | Sheet | Inline ("Add Watering") | Cancel + Save |
| SettingsView | Sheet | Inline ("Settings") | Done |
| HowToView | Push | Large ("How To") | Back only |
