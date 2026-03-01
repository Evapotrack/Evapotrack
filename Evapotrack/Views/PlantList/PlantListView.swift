// PlantListView.swift
// Evapotrack
//
// Shows all plants in a grow, sorted by name.
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

    private var preferredColorScheme: ColorScheme {
        settingsVM.settings.appearanceMode == .dark ? .dark : .light
    }

    /// Plants sorted by name, derived from the grow relationship.
    private var plants: [Plant] {
        grow.plants.sorted {
            $0.plantName.localizedCaseInsensitiveCompare($1.plantName) == .orderedAscending
        }
    }

    /// The plant currently selected for deletion.
    private var selectedPlant: Plant? {
        guard let id = selectedPlantID else { return nil }
        return plants.first(where: { $0.id == id })
    }

    var body: some View {
        List {
            // Grow name centered below toolbar, above plant rows
            Section {
                Text(grow.growName)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.evPrimaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }

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
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.evBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: PlantNavID.self) { navID in
            if let plant = plants.first(where: { $0.id == navID.id }) {
                PlantDashboardView(plant: plant)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isShowingCreatePlant = true } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Add Plant")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isShowingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(selectedPlantID != nil ? .red : .evSlateGray)
                        .padding(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.evInkBlack, lineWidth: 2)
                        )
                }
                .disabled(selectedPlantID == nil)
                .accessibilityLabel("Delete Plant")
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button { isShowingSettings = true } label: {
                    Image(systemName: "gear")
                        .font(.body)
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
                        .font(.body)
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
            .preferredColorScheme(preferredColorScheme)
        }
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                SettingsView()
            }
            .preferredColorScheme(preferredColorScheme)
        }
        .onAppear {
            selectedPlantID = nil
        }
        .overlay {
            if plants.isEmpty {
                ContentUnavailableView {
                    Label("No Plants Yet", systemImage: "leaf")
                } description: {
                    HStack(spacing: 4) {
                        Text("Tap")
                        Text("+")
                            .font(.title2)
                            .fontWeight(.black)
                        Text("to add your first plant.")
                    }
                }
            }
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
    }

    // MARK: - Actions

    private func toggleSelection(for plant: Plant) {
        if selectedPlantID == plant.id {
            selectedPlantID = nil
        } else {
            selectedPlantID = plant.id
        }
    }

    private func deletePlant(_ plant: Plant) {
        let service = PlantService(modelContext: modelContext)
        service.deletePlant(plant)
        selectedPlantID = nil
    }
}
