// HistoryView.swift
// Evapotrack
//
// Dedicated full-screen view for watering log history.
// Shows all logs with stats, selection, and delete functionality.
// Only one log may be expanded at a time.
// Chart button toggles between chart view and log list.
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
            } else if isShowingChart && vm.wateringLogs.count >= 2 {
                // Chart mode — replaces log list
                Section {
                    retainedChart
                } header: {
                    Label {
                        Text("Retained Over Time")
                    } icon: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                    }
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
                }
            } else {
                // Log list mode
                ForEach(groupedLogs, id: \.date) { group in
                    Section {
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
                    } header: {
                        Text(sectionTitle(for: group.date))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.evDeepNavy)
                            .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.evBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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
                    Image(systemName: isShowingChart ? "list.bullet" : "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.evPrimaryBlue)
                }
                .disabled(vm.wateringLogs.count < 2)
                .accessibilityLabel(isShowingChart ? "Show Logs" : "Show Chart")
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

    /// Evenly spaced indices from 0..<count, always including first and last.
    private static func evenlySpacedIndices(count: Int, max maxCount: Int) -> Set<Int> {
        guard count > 0 else { return [] }
        guard count > maxCount else { return Set(0..<count) }
        var indices = Set<Int>()
        for i in 0..<maxCount {
            let index = i * (count - 1) / (maxCount - 1)
            indices.insert(index)
        }
        return indices
    }

    @ViewBuilder
    private var retainedChart: some View {
        let chartData = vm.wateringLogs.sorted { $0.dateTime < $1.dateTime }
        let dotIndices = Self.evenlySpacedIndices(count: chartData.count, max: 10)
        let dateLabelDates: [Date] = chartData.count >= 2
            ? [chartData.first!.dateTime, chartData.last!.dateTime]
            : chartData.map(\.dateTime)

        Chart(Array(chartData.enumerated()), id: \.element.id) { index, log in
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

            if dotIndices.contains(index) {
                PointMark(
                    x: .value("Date", log.dateTime),
                    y: .value("Retained", UnitConversionService.fromLiters(log.retained, to: waterUnit))
                )
                .foregroundStyle(Color.evPrimaryBlue)
                .symbolSize(24)
            }
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
            AxisMarks(values: dateLabelDates) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.caption2)
                    .foregroundStyle(Color.evSecondaryText)
            }
        }
        .frame(height: sizeClass == .regular ? 260 : 180)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Retained water over time chart with \(chartData.count) data points")
    }
}
