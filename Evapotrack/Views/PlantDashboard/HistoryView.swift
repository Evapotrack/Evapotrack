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
    var startInChartMode: Bool = false

    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsViewModel.self) private var settingsVM
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedLogID: UUID?
    @State private var expandedLogID: UUID?
    @State private var isShowingDeleteAlert = false
    @State private var isShowingChart = false
    @State private var showTemperature = false
    @State private var showHumidity = false

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
            return Strings.today
        } else if calendar.isDateInYesterday(date) {
            return Strings.yesterday
        } else {
            return date.shortFormatted
        }
    }

    private var hasTemperatureData: Bool {
        vm.wateringLogs.contains { $0.temperatureCelsius != nil }
    }

    private var hasHumidityData: Bool {
        vm.wateringLogs.contains { $0.humidityPercent != nil }
    }

    private var hasOverlays: Bool {
        showTemperature || showHumidity
    }

    private var chartHeaderTitle: String {
        var parts = [Strings.retained]
        if showTemperature { parts.append(Strings.temp) }
        if showHumidity { parts.append(Strings.humidity) }
        return parts.joined(separator: " · ") + Strings.overTime
    }

    var body: some View {
        @Bindable var vm = vm
        List {
            if vm.wateringLogs.isEmpty {
                Text(Strings.noWateringLogsYet)
                    .foregroundStyle(Color.evSecondaryText)
            } else if isShowingChart && vm.wateringLogs.count >= 2 {
                // Chart mode — replaces log list
                Section {
                    chartTogglePills
                    retainedChart
                } header: {
                    Label {
                        Text(chartHeaderTitle)
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
                            .foregroundStyle(Color.evPrimaryBlue)
                            .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(8)
        .id(settingsVM.settings.language)
        .scrollContentBackground(.hidden)
        .background(Color.evBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Button {
                        isShowingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(selectedLogID != nil ? .red : .evSlateGray)
                    }
                    .disabled(selectedLogID == nil)
                    .accessibilityLabel(Strings.deleteLogLabel)

                    Button { vm.isShowingAddWatering = true } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel(Strings.addWateringLabel)
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.evPrimaryBlue)
                }
                .accessibilityLabel(Strings.backLabel)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink {
                    HowToView(context: .chart)
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.evPrimaryBlue)
                }
                .accessibilityLabel(Strings.helpLabel)
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
                .accessibilityLabel(isShowingChart ? Strings.showLogs : Strings.showChart)
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
                    title: Strings.deleteLog,
                    message: Strings.deleteLogMessage(log.dateTime.longFormatted),
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
        .onAppear {
            if startInChartMode {
                isShowingChart = true
            }
        }
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

    // MARK: - Chart Toggle Pills

    @ViewBuilder
    private var chartTogglePills: some View {
        let tempAvailable = hasTemperatureData
        let humidityAvailable = hasHumidityData

        HStack(spacing: 8) {
            chartPill(label: Strings.retained, color: .evPrimaryBlue, isActive: true, enabled: true) {}

            chartPill(label: Strings.temp, color: .evWarmOrange, isActive: showTemperature, enabled: tempAvailable) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showTemperature.toggle()
                }
            }

            chartPill(label: Strings.humidity, color: .evSoftPurple, isActive: showHumidity, enabled: humidityAvailable) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showHumidity.toggle()
                }
            }

            Spacer()
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func chartPill(label: String, color: Color, isActive: Bool, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                isActive
                    ? color.opacity(0.15)
                    : Color.clear
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isActive ? color : Color.evSlateGray.opacity(0.4), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(isActive ? color : Color.evSecondaryText)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1.0 : 0.4)
        .accessibilityLabel(Strings.chartLineName(label))
        .accessibilityHint(enabled ? (isActive ? Strings.chartLineActive() : Strings.chartLineInactive()) : Strings.chartLineNoData(label.lowercased()))
        .accessibilityAddTraits(isActive ? .isSelected : [])
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
        guard let firstDate = chartData.first?.dateTime,
              let lastDate = chartData.last?.dateTime else { return }
        let xDomain = firstDate...max(lastDate, firstDate.addingTimeInterval(60))
        let chartHeight: CGFloat = sizeClass == .regular ? 260 : 180

        ZStack {
            // Primary chart: Retained water (left Y-axis)
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
                    .symbolSize(30)
                    .annotation(position: .overlay) {
                        Circle()
                            .stroke(Color.evBackground, lineWidth: 1.5)
                            .frame(width: 7, height: 7)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.evSlateGray.opacity(0.3))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(Color.evSecondaryText)
                }
            }
            .chartXScale(domain: xDomain)
            .chartXAxis(.hidden)
            .frame(height: chartHeight)

            // Overlay chart: Temperature and/or Humidity (right Y-axis)
            if hasOverlays {
                overlayChart(chartData: chartData, xDomain: xDomain)
                    .frame(height: chartHeight)
            }
        }
        .padding(.horizontal, 4)
        .overlay(alignment: .bottom) {
            if firstDate != lastDate {
                HStack {
                    Text(firstDate, format: .dateTime.month(.abbreviated).day())
                    Spacer()
                    Text(lastDate, format: .dateTime.month(.abbreviated).day())
                }
                .font(.caption2)
                .foregroundStyle(Color.evSecondaryText)
                .padding(.horizontal, 4)
                .offset(y: 20)
            }
        }
        .padding(.bottom, firstDate != lastDate ? 20 : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chartAccessibilityLabel(dataCount: chartData.count))
    }

    @ViewBuilder
    private func overlayChart(chartData: [WateringLog], xDomain: ClosedRange<Date>) -> some View {
        let tempUnit = settingsVM.settings.temperatureUnit

        let bothActive = showTemperature && showHumidity

        if showTemperature {
            temperatureChart(chartData: chartData, tempUnit: tempUnit, xDomain: xDomain, showAxis: !bothActive)
        }

        if showHumidity {
            humidityChart(chartData: chartData, xDomain: xDomain, showAxis: !bothActive)
        }
    }

    @ViewBuilder
    private func temperatureChart(chartData: [WateringLog], tempUnit: TemperatureUnit, xDomain: ClosedRange<Date>, showAxis: Bool) -> some View {
        Chart {
            ForEach(chartData.filter { $0.temperatureCelsius != nil }, id: \.id) { log in
                LineMark(
                    x: .value("Date", log.dateTime),
                    y: .value("Temp", UnitConversionService.fromCelsius(log.temperatureCelsius!, to: tempUnit))
                )
                .foregroundStyle(Color.evWarmOrange)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartYAxis {
            if showAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { _ in
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(Color.evWarmOrange)
                }
            }
        }
        .chartXScale(domain: xDomain)
        .chartXAxis(.hidden)
        .chartLegend(.hidden)
    }

    @ViewBuilder
    private func humidityChart(chartData: [WateringLog], xDomain: ClosedRange<Date>, showAxis: Bool) -> some View {
        Chart {
            ForEach(chartData.filter { $0.humidityPercent != nil }, id: \.id) { log in
                LineMark(
                    x: .value("Date", log.dateTime),
                    y: .value("Humidity", log.humidityPercent!)
                )
                .foregroundStyle(Color.evSoftPurple)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartYAxis {
            if showAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { _ in
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(Color.evSoftPurple)
                }
            }
        }
        .chartXScale(domain: xDomain)
        .chartXAxis(.hidden)
        .chartLegend(.hidden)
    }

    private var overlayAxisColor: Color {
        if showTemperature && !showHumidity { return .evWarmOrange }
        if showHumidity && !showTemperature { return .evSoftPurple }
        return .evSecondaryText
    }

    private func chartAccessibilityLabel(dataCount: Int) -> String {
        var lines = [Strings.retainedWater]
        if showTemperature { lines.append(Strings.temperatureLower) }
        if showHumidity { lines.append(Strings.humidityLower) }
        return Strings.chartAccessibility(lines, dataCount: dataCount)
    }
}
