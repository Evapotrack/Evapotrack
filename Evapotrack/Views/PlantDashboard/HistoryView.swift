// HistoryView.swift
// Evapotrack
//
// Dedicated full-screen view for watering log history.
// Shows all logs with stats, selection, and delete functionality.
// Only one log may be expanded at a time.
// Pushed via NavigationLink from the plant dashboard.

import SwiftUI
import Charts

struct HistoryView: View {
    var vm: PlantDashboardViewModel
    let waterUnit: WaterUnit
    let maxRetentionCapacity: Double

    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsViewModel.self) private var settingsVM
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedLogID: UUID?
    @State private var expandedLogID: UUID?
    @State private var isShowingDeleteAlert = false
    @State private var isShowingChart = false

    private var selectedLog: WateringLog? {
        guard let id = selectedLogID else { return nil }
        return vm.wateringLogs.first(where: { $0.id == id })
    }

    /// Logs grouped by day, sorted most recent day first, logs within each day most recent first.
    private var groupedLogs: [(date: Date, logs: [WateringLog])] {
        let sorted = vm.wateringLogs.sorted { $0.dateTime > $1.dateTime }
        let grouped = Dictionary(grouping: sorted) { $0.dateTime.startOfDay }
        return grouped
            .map { (date: $0.key, logs: $0.value) }
            .sorted { $0.date > $1.date }
    }

    /// Human-friendly section header for a date.
    private func sectionTitle(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.shortFormatted
        }
    }

    var body: some View {
        @Bindable var vm = vm
        List {
            if vm.wateringLogs.isEmpty {
                Text("No watering logs yet.")
                    .foregroundStyle(Color.evSecondaryText)
            } else {
                if isShowingChart && vm.wateringLogs.count >= 2 {
                    Section {
                        retainedChart
                    } header: {
                        Text("Retained Over Time")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.evDeepNavy)
                            .textCase(nil)
                    }
                }

                ForEach(groupedLogs, id: \.date) { group in
                    Section(header: Text(sectionTitle(for: group.date))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.evDeepNavy)
                        .textCase(nil)
                    ) {
                        ForEach(group.logs, id: \.id) { log in
                            WateringLogRowView(
                                log: log,
                                waterUnit: waterUnit,
                                temperatureUnit: settingsVM.settings.temperatureUnit,
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
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.evBackground)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
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
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.evPrimaryBlue)
                }
                .accessibilityLabel("Back")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isShowingChart.toggle()
                    }
                } label: {
                    Image(systemName: isShowingChart ? "chart.line.uptrend.xyaxis.circle.fill" : "chart.line.uptrend.xyaxis.circle")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.evPrimaryBlue)
                }
                .disabled(vm.wateringLogs.count < 2)
                .accessibilityLabel(isShowingChart ? "Hide Chart" : "Show Chart")
                .accessibilityHint("Toggle the retained water chart")
            }
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
        .sheet(isPresented: $vm.isShowingAddWatering, onDismiss: { vm.loadData() }) {
            NavigationStack {
                AddWateringLogView(plant: vm.plant)
            }
            .preferredColorScheme(settingsVM.colorScheme)
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
                        vm.deleteLog(log)
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

    // MARK: - Chart

    @ViewBuilder
    private var retainedChart: some View {
        let sorted = vm.wateringLogs.sorted { $0.dateTime < $1.dateTime }
        Chart(sorted, id: \.id) { log in
            AreaMark(
                x: .value("Date", log.dateTime),
                y: .value("Retained", UnitConversionService.fromLiters(log.retained, to: waterUnit))
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.evPrimaryBlue.opacity(0.25), Color.evPrimaryBlue.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Date", log.dateTime),
                y: .value("Retained", UnitConversionService.fromLiters(log.retained, to: waterUnit))
            )
            .foregroundStyle(Color.evPrimaryBlue)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Date", log.dateTime),
                y: .value("Retained", UnitConversionService.fromLiters(log.retained, to: waterUnit))
            )
            .foregroundStyle(Color.evPrimaryBlue)
            .symbolSize(24)
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    .foregroundStyle(Color.evSlateGray.opacity(0.2))
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(Color.evSecondaryText)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.caption2)
                    .foregroundStyle(Color.evSecondaryText)
            }
        }
        .frame(height: sizeClass == .regular ? 260 : 180)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Retained water over time chart with \(sorted.count) data points")
    }
}
