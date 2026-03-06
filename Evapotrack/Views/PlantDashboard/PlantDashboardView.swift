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

            // Plant details
            Section {
                HStack {
                    plantInfoCell("Pot", vm.plant.potSize.isEmpty ? "—" : vm.plant.potSize)
                    Spacer()
                    plantInfoCell("Medium", vm.plant.mediumType.isEmpty ? "—" : vm.plant.mediumType)
                    Spacer()
                    plantInfoCell("Goal Runoff", DisplayFormatter.percent(vm.plant.goalRunoffPercent))
                }
            } header: {
                Label {
                    Text("Plant Info")
                } icon: {
                    Image(systemName: "leaf")
                }
                .font(.title2.weight(.bold))
                .foregroundStyle(.evDeepNavy)
                .textCase(nil)
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
                vm: vm,
                waterUnit: waterUnit,
                maxRetentionCapacity: vm.plant.maxRetentionCapacity
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
                        .font(.title3)
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
                        .font(.title3)
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
            .preferredColorScheme(settingsVM.colorScheme)
        }
        .sheet(isPresented: $vm.isShowingSettings) {
            NavigationStack {
                SettingsView()
            }
            .preferredColorScheme(settingsVM.colorScheme)
        }
        .onAppear {
            vm.configure(modelContext: modelContext)
            vm.loadData()
        }
        .alert("Error", isPresented: Binding(
            get: { vm.deleteError != nil },
            set: { if !$0 { vm.deleteError = nil } }
        )) {
            Button("OK") { vm.deleteError = nil }
        } message: {
            Text(vm.deleteError ?? "")
        }
    }

    private func plantInfoCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(Color.evSecondaryText)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.evPrimaryBlue)
        }
    }
}
