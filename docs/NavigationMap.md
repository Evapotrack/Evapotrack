# Evapotrack - Navigation Map

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
│   │   ├── [Push] HistoryView(logs:)
│   │   │       via NavigationLink in HistoryPanelView
│   │   │
│   │   ├── [Push] HowToView(context: .addWatering)
│   │   │       via NavigationLink in toolbar
│   │   │
│   │   ├── [Sheet] AddWateringLogView(plant:)
│   │   │       via isShowingAddWatering
│   │   │
│   │   └── [Sheet] SettingsView()
│   │           via isShowingSettings
│   │
│   ├── [Push] HowToView(context: .general)
│   │       via NavigationLink in toolbar
│   │
│   ├── [Sheet] CreatePlantView(grow:)
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
| Leading | Gear icon | Opens Settings sheet |
| Leading | Question mark icon | Pushes HowToView |
| Trailing | Trash icon | Triggers delete confirmation |
| Primary Action | Plus icon | Opens create/add sheet |

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
| HistoryView | Push | Large ("History") | Yes (trash only) |
| CreateGrowView | Sheet | Inline ("Add Grow") | Cancel + Save |
| CreatePlantView | Sheet | Inline ("Add Plant") | Cancel + Save |
| AddWateringLogView | Sheet | Inline ("Add Watering") | Cancel + Save |
| SettingsView | Sheet | Inline ("Settings") | Done |
| HowToView | Push | Large ("How To") | None |
