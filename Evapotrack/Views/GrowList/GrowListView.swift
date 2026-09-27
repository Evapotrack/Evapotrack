// © 2026 Evapotrack. All rights reserved.
// GrowListView.swift
// Evapotrack
//
// Root view: shows all grows sorted by creation date (newest first).
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
    @State private var isShowingLimitExceeded = false
    @State private var saveError: String?
    @ScaledMetric(relativeTo: .largeTitle) private var emptyIconSize: CGFloat = 56

    private var selectedGrow: Grow? {
        guard let id = selectedGrowID else { return nil }
        return grows.first(where: { $0.id == id })
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
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
                } header: {
                    HStack {
                        Text(Strings.grows)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.evSecondaryText)
                            .textCase(nil)
                        Spacer()
                        Text("\(grows.count)/\(AppConstants.maxGrowCount)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.evSlateGray)
                            .textCase(nil)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Strings.growsCount(grows.count, max: AppConstants.maxGrowCount))
                }
            }
            .listStyle(.insetGrouped)
            .id(settingsVM.settings.language)
            .scrollContentBackground(.hidden)
            .background(Color.evBackground)
            .iPadTopPadding()
            .navigationTitle(Strings.myGrows)
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: GrowNavID.self) { navID in
                if let grow = grows.first(where: { $0.id == navID.id }) {
                    PlantListView(grow: grow)
                } else {
                    ContentUnavailableView(Strings.growNotFound, systemImage: "exclamationmark.triangle")
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        Button {
                            isShowingDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(selectedGrowID != nil ? .red : .evSlateGray)
                                .padding(.leading, 8)
                        }
                        .disabled(selectedGrowID == nil)
                        .accessibilityLabel(Strings.deleteGrowLabel)

                        Button {
                            if grows.count >= AppConstants.maxGrowCount {
                                isShowingLimitExceeded = true
                            } else {
                                isShowingCreateGrow = true
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3)
                                .fontWeight(.bold)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .accessibilityLabel(grows.count >= AppConstants.maxGrowCount ? Strings.maxGrowsReached(AppConstants.maxGrowCount) : Strings.addGrowLabel)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { isShowingSettings = true } label: {
                        Image(systemName: "gear")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.evPrimaryBlue)
                    }
                    .accessibilityLabel(Strings.settingsLabel)
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
                    .accessibilityLabel(Strings.helpLabel)
                }
            }
            .adaptiveSheet(isPresented: $isShowingCreateGrow) {
                NavigationStack {
                    CreateGrowView()
                }
                .preferredColorScheme(settingsVM.colorScheme)
            }
            .adaptiveSheet(isPresented: $isShowingSettings) {
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
                        title: Strings.deleteGrow,
                        message: Strings.deleteGrowMessage(grow.growName),
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
            .overlay {
                if isShowingLimitExceeded {
                    LimitExceededView(
                        title: Strings.growLimitReached,
                        message: Strings.growLimitMessage(AppConstants.maxGrowCount),
                        onClose: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowingLimitExceeded = false
                            }
                        }
                    )
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isShowingLimitExceeded)
            .alert(Strings.error, isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button(Strings.ok) { saveError = nil }
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
                .font(.system(size: emptyIconSize))
                .foregroundStyle(Color.evPrimaryBlue)
                .accessibilityHidden(true)

            Text(Strings.noGrowsCreated)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.evDeepNavy)

            HStack(spacing: 4) {
                Text(Strings.tap)
                    .foregroundStyle(Color.evSecondaryText)
                Image(systemName: "plus")
                    .font(.body.weight(.black))
                    .foregroundStyle(Color.evPrimaryBlue)
                    .accessibilityHidden(true)
                Text(Strings.tapToCreateGrow)
                    .foregroundStyle(Color.evSecondaryText)
            }
            .font(.body)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Strings.tapPlusCreateGrow)

            VStack(alignment: .leading, spacing: 8) {
                NavigationLink {
                    HowToView(context: .general)
                } label: {
                    Label(Strings.howToGetStarted, systemImage: "questionmark.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.evPrimaryBlue)
                }

                Button {
                    loadExampleData()
                } label: {
                    Label(Strings.tryExampleData, systemImage: "tray.and.arrow.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.evPrimaryBlue)
                }
                .accessibilityLabel(Strings.loadExampleData)
            }
            .padding(.top, 4)
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

    private func loadExampleData() {
        do {
            try ExampleDataService(modelContext: modelContext).loadExampleGrow()
            HapticService.success()
        } catch {
            saveError = Strings.failedToLoadExampleData
        }
    }

    private func deleteGrow(_ grow: Grow) {
        let service = GrowService(modelContext: modelContext)
        do {
            try service.deleteGrow(grow)
        } catch {
            saveError = Strings.failedDeleteGrow
        }
        selectedGrowID = nil
    }
}
