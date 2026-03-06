// PlantListView.swift
// Evapotrack
//
// Shows all plants in a grow, sorted by most recently created first.
// Each row shows plantName only with a left-side circular selection indicator.
// Selection is single-select and resets on appear.
// Delete requires exactly one selected plant and shows a confirmation overlay.
// No swipe-to-delete.
// Pushed inside GrowListView's NavigationStack — does not own its own.

import SwiftUI
import SwiftData

/// Typed navigation value to avoid UUID collision with GrowNavID.
struct PlantNavID: Hashable {
    let id: UUID
}

struct PlantListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SettingsViewModel.self) private var settingsVM

    let grow: Grow

    @State private var selectedPlantID: UUID?
    @State private var isShowingCreatePlant = false
    @State private var isShowingSettings = false
    @State private var isShowingDeleteAlert = false
    @State private var isShowingLimitExceeded = false
    @State private var limitExceededMessage = ""
    @State private var saveError: String?
    @Environment(\.dismiss) private var dismiss

    /// Plants sorted by most recently created first.
    private var plants: [Plant] {
        grow.plants.sorted { $0.createdAt > $1.createdAt }
    }

    /// The plant currently selected for deletion.
    private var selectedPlant: Plant? {
        guard let id = selectedPlantID else { return nil }
        return plants.first(where: { $0.id == id })
    }

    var body: some View {
        List {
            Section {
            ForEach(plants, id: \.id) { plant in
                NavigationLink(value: PlantNavID(id: plant.id)) {
                    PlantRowView(
                        plant: plant,
                        isSelected: selectedPlantID == plant.id,
                        onToggleSelection: {
                            toggleSelection(for: plant)
                        }
                    )
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            } header: {
                HStack {
                    Text("Plant list")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.evSecondaryText)
                        .textCase(nil)
                    Spacer()
                    Text("\(plants.count)/\(AppConstants.maxPlantsPerGrow)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.evSlateGray)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.evBackground)
        .navigationTitle(grow.growName)
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(for: PlantNavID.self) { navID in
            if let plant = plants.first(where: { $0.id == navID.id }) {
                PlantDashboardView(plant: plant)
            } else {
                ContentUnavailableView("Plant Not Found", systemImage: "exclamationmark.triangle")
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if plants.count >= AppConstants.maxPlantsPerGrow {
                        limitExceededMessage = "You've reached the maximum of \(AppConstants.maxPlantsPerGrow) plants per grow. Delete a plant to create a new one."
                        isShowingLimitExceeded = true
                    } else if totalPlantCount() >= AppConstants.maxTotalPlants {
                        limitExceededMessage = "You've reached the maximum of \(AppConstants.maxTotalPlants) total plants. Delete a plant from any grow to create a new one."
                        isShowingLimitExceeded = true
                    } else {
                        isShowingCreatePlant = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel(plants.count >= AppConstants.maxPlantsPerGrow ? "Maximum of \(AppConstants.maxPlantsPerGrow) plants reached" : "Add Plant")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isShowingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(selectedPlantID != nil ? .red : .evSlateGray)
                }
                .disabled(selectedPlantID == nil)
                .accessibilityLabel("Delete Plant")
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.evPrimaryBlue)
                }
                .accessibilityLabel("Back")
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button { isShowingSettings = true } label: {
                    Image(systemName: "gear")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.evPrimaryBlue)
                }
                .accessibilityLabel("Settings")
            }
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink {
                    HowToView(context: .general)
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.evPrimaryBlue)
                }
                .accessibilityLabel("Help")
            }
        }
        .sheet(isPresented: $isShowingCreatePlant) {
            NavigationStack {
                CreatePlantView(grow: grow)
            }
            .preferredColorScheme(settingsVM.colorScheme)
        }
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                SettingsView(grow: grow)
            }
            .preferredColorScheme(settingsVM.colorScheme)
        }
        .onAppear {
            selectedPlantID = nil
        }
        .overlay {
            if plants.isEmpty { emptyStateView }
        }
        .overlay {
            if isShowingDeleteAlert, let plant = selectedPlant {
                DeleteConfirmationView(
                    title: "Delete Plant",
                    message: "Are you sure you want to delete \"\(plant.plantName)\"? All watering logs for this plant will be permanently deleted. This action cannot be undone.",
                    onDelete: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isShowingDeleteAlert = false
                        }
                        deletePlant(plant)
                    },
                    onCancel: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isShowingDeleteAlert = false
                        }
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isShowingDeleteAlert)
        .overlay {
            if isShowingLimitExceeded {
                LimitExceededView(
                    title: "Plant Limit Reached",
                    message: limitExceededMessage,
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isShowingLimitExceeded = false
                        }
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isShowingLimitExceeded)
        .alert("Error", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.evPrimaryBlue)

            Text("No Plants Yet")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.evDeepNavy)

            HStack(spacing: 4) {
                Text("Tap")
                    .foregroundStyle(Color.evSecondaryText)
                Image(systemName: "plus")
                    .font(.body.weight(.black))
                    .foregroundStyle(Color.evPrimaryBlue)
                Text("to add your first plant.")
                    .foregroundStyle(Color.evSecondaryText)
            }
            .font(.body)
        }
    }

    // MARK: - Actions

    private func toggleSelection(for plant: Plant) {
        HapticService.light()
        if selectedPlantID == plant.id {
            selectedPlantID = nil
        } else {
            selectedPlantID = plant.id
        }
    }

    private func totalPlantCount() -> Int {
        let descriptor = FetchDescriptor<Plant>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private func deletePlant(_ plant: Plant) {
        let service = PlantService(modelContext: modelContext)
        do {
            try service.deletePlant(plant)
        } catch {
            saveError = "Failed to delete plant. Please try again."
        }
        selectedPlantID = nil
    }
}
