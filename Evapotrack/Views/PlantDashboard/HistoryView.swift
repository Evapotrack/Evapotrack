// HistoryView.swift
// Evapotrack
//
// Dedicated full-screen view for watering log history.
// Shows all logs with stats, selection, and delete functionality.
// Only one log may be expanded at a time.
// Pushed via NavigationLink from the plant dashboard.

import SwiftUI

struct HistoryView: View {
    let logs: [WateringLog]
    let waterUnit: WaterUnit
    let maxRetentionCapacity: Double
    let onDeleteLog: (WateringLog) -> Void

    @State private var selectedLogID: UUID?
    @State private var expandedLogID: UUID?
    @State private var isShowingDeleteAlert = false

    private var selectedLog: WateringLog? {
        guard let id = selectedLogID else { return nil }
        return logs.first(where: { $0.id == id })
    }

    var body: some View {
        List {
            if logs.isEmpty {
                Text("No watering logs yet.")
                    .foregroundStyle(Color.evSecondaryText)
            } else {
                ForEach(logs, id: \.id) { log in
                    WateringLogRowView(
                        log: log,
                        waterUnit: waterUnit,
                        maxRetentionCapacity: maxRetentionCapacity,
                        isSelected: selectedLogID == log.id,
                        isExpanded: expandedLogID == log.id,
                        onToggleSelection: {
                            toggleSelection(for: log)
                        },
                        onToggleExpansion: {
                            toggleExpansion(for: log)
                        }
                    )
                    .listRowBackground(
                        expandedLogID == log.id
                            ? Color.evFrostBlue.opacity(0.15)
                            : nil
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.evBackground)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isShowingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(selectedLogID != nil ? .red : .evSlateGray)
                }
                .disabled(selectedLogID == nil)
                .accessibilityLabel("Delete Log")
            }
        }
        .overlay {
            if isShowingDeleteAlert, let log = selectedLog {
                DeleteConfirmationView(
                    title: "Delete Log",
                    message: "Delete the log from \(log.dateTime.longFormatted)? This action cannot be undone.",
                    onDelete: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isShowingDeleteAlert = false
                        }
                        onDeleteLog(log)
                        selectedLogID = nil
                        expandedLogID = nil
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

    private func toggleSelection(for log: WateringLog) {
        HapticService.light()
        if selectedLogID == log.id {
            selectedLogID = nil
        } else {
            selectedLogID = log.id
        }
    }

    private func toggleExpansion(for log: WateringLog) {
        if expandedLogID == log.id {
            expandedLogID = nil
        } else {
            expandedLogID = log.id
        }
    }
}
