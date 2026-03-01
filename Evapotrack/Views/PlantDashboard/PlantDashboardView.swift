// PlantDashboardView.swift
// Evapotrack
//
// Dashboard for a single plant: summary, insights, and history panels.
// All displayed values respect the user's chosen display units.
// History is a NavigationLink to a dedicated screen with select/delete.
// Settings modal, How To push, Add Watering modal.

import SwiftUI

struct PlantDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SettingsViewModel.self) private var settingsVM
    @State private var vm: PlantDashboardViewModel

    init(plant: Plant) {
        _vm = State(wrappedValue: PlantDashboardViewModel(plant: plant))
    }

    private var waterUnit: WaterUnit { settingsVM.settings.waterUnit }

    private var preferredColorScheme: ColorScheme {
        settingsVM.settings.appearanceMode == .dark ? .dark : .light
    }

    var body: some View {
        List {
            // Plant name centered below toolbar, above panels
            Section {
                Text(vm.plant.plantName)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.evPrimaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }

            SummaryPanelView(
                lastLog: vm.lastLog,
                maxRetentionCapacity: vm.plant.maxRetentionCapacity,
                waterUnit: waterUnit
            )

            InsightsPanelView(
                averageRetained: vm.averageRetained,
                nextRecommendation: vm.nextRecommendation,
                waterUnit: waterUnit
            )

            HistoryPanelView(
                logCount: vm.wateringLogs.count,
                logs: vm.wateringLogs,
                waterUnit: waterUnit,
                maxRetentionCapacity: vm.plant.maxRetentionCapacity,
                onDeleteLog: { log in
                    vm.deleteLog(log)
                }
            )
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.evBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { vm.isShowingAddWatering = true } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Add Watering")
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button { vm.isShowingSettings = true } label: {
                    Image(systemName: "gear")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.evPrimaryBlue)
                }
                .accessibilityLabel("Settings")
            }
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink {
                    HowToView(context: .addWatering)
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.evPrimaryBlue)
                }
                .accessibilityLabel("Help")
            }
        }
        .sheet(isPresented: $vm.isShowingAddWatering, onDismiss: { vm.loadData() }) {
            NavigationStack {
                AddWateringLogView(plant: vm.plant)
            }
            .preferredColorScheme(preferredColorScheme)
        }
        .sheet(isPresented: $vm.isShowingSettings) {
            NavigationStack {
                SettingsView()
            }
            .preferredColorScheme(preferredColorScheme)
        }
        .onAppear {
            vm.configure(modelContext: modelContext)
            vm.loadData()
        }
    }
}
