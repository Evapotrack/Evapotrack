// GrowListView.swift
// Evapotrack
//
// Root view: shows all grows sorted by name.
// Each row shows growName with a left-side circular selection indicator.
// Selection is single-select and resets on appear.
// Delete requires exactly one selected grow and shows a confirmation overlay.
// Deleting a grow cascade-deletes all its plants and their logs.

import SwiftUI
import SwiftData

/// Typed navigation value to avoid UUID collision with PlantNavID.
struct GrowNavID: Hashable {
    let id: UUID
}

struct GrowListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SettingsViewModel.self) private var settingsVM
    @Query(sort: \Grow.createdAt, order: .reverse) private var grows: [Grow]

    @State private var selectedGrowID: UUID?
    @State private var isShowingCreateGrow = false
    @State private var isShowingSettings = false
    @State private var isShowingDeleteAlert = false
    @State private var saveError: String?

    private var selectedGrow: Grow? {
        guard let id = selectedGrowID else { return nil }
        return grows.first(where: { $0.id == id })
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grows, id: \.id) { grow in
                    NavigationLink(value: GrowNavID(id: grow.id)) {
                        GrowRowView(
                            grow: grow,
                            isSelected: selectedGrowID == grow.id,
                            onToggleSelection: {
                                toggleSelection(for: grow)
                            }
                        )
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.evBackground)
            .navigationTitle("My Grows")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: GrowNavID.self) { navID in
                if let grow = grows.first(where: { $0.id == navID.id }) {
                    PlantListView(grow: grow)
                } else {
                    ContentUnavailableView("Grow Not Found", systemImage: "exclamationmark.triangle")
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { isShowingCreateGrow = true } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .disabled(grows.count >= AppConstants.maxGrowCount)
                    .accessibilityLabel(grows.count >= AppConstants.maxGrowCount ? "Maximum of \(AppConstants.maxGrowCount) grows reached" : "Add Grow")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(selectedGrowID != nil ? .red : .evSlateGray)
                    }
                    .disabled(selectedGrowID == nil)
                    .accessibilityLabel("Delete Grow")
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
            .sheet(isPresented: $isShowingCreateGrow) {
                NavigationStack {
                    CreateGrowView()
                }
                .preferredColorScheme(settingsVM.colorScheme)
            }
            .sheet(isPresented: $isShowingSettings) {
                NavigationStack {
                    SettingsView()
                }
                .preferredColorScheme(settingsVM.colorScheme)
            }
            .onAppear {
                selectedGrowID = nil
            }
            .overlay {
                if grows.isEmpty { emptyStateView }
            }
            .overlay {
                if isShowingDeleteAlert, let grow = selectedGrow {
                    DeleteConfirmationView(
                        title: "Delete Grow",
                        message: "Are you sure you want to delete \"\(grow.growName)\"? All plants and their watering logs in this grow will be permanently deleted. This action cannot be undone.",
                        onDelete: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowingDeleteAlert = false
                            }
                            deleteGrow(grow)
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
            .alert("Error", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.evPrimaryBlue)

            Text("No Grows Yet")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.evDeepNavy)

            HStack(spacing: 4) {
                Text("Tap")
                    .foregroundStyle(Color.evSecondaryText)
                Image(systemName: "plus")
                    .font(.body.weight(.black))
                    .foregroundStyle(Color.evPrimaryBlue)
                Text("to create your first grow.")
                    .foregroundStyle(Color.evSecondaryText)
            }
            .font(.body)
        }
    }

    // MARK: - Actions

    private func toggleSelection(for grow: Grow) {
        HapticService.light()
        if selectedGrowID == grow.id {
            selectedGrowID = nil
        } else {
            selectedGrowID = grow.id
        }
    }

    private func deleteGrow(_ grow: Grow) {
        let service = GrowService(modelContext: modelContext)
        do {
            try service.deleteGrow(grow)
        } catch {
            saveError = "Failed to delete grow. Please try again."
        }
        selectedGrowID = nil
    }
}
