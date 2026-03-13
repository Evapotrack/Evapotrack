// SettingsView.swift
// Evapotrack
//
// Settings screen for water and temperature display units,
// appearance mode, and optional per-grow data export.
// When opened from PlantListView with a grow, shows a
// Download Data section for that grow. When opened from
// GrowListView (no grow), the export section is hidden.
// Changes persist immediately via auto-save — no stored
// SwiftData values are ever modified.

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var settingsVM
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// The grow to offer data export for. Nil when opened from GrowListView.
    var grow: Grow?

    @State private var isShowingExport = false
    @State private var exportDocument: GrowExportDocument?
    @State private var exportFilename = "data"
    @State private var showExampleLoaded = false

    private var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Evapotrack v\(version) (\(build))"
    }

    var body: some View {
        @Bindable var settingsVM = settingsVM
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Water Unit")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.evPrimaryText)
                    Picker("Water Unit", selection: $settingsVM.settings.waterUnit) {
                        ForEach(WaterUnit.allCases) { unit in
                            Text(unit.abbreviation).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Temperature Unit")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.evPrimaryText)
                    Picker("Temperature Unit", selection: $settingsVM.settings.temperatureUnit) {
                        ForEach(TemperatureUnit.allCases) { unit in
                            Text(unit.abbreviation).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Display Units")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            } footer: {
                Text("Changing units updates how values are displayed. Stored data is never modified.")
                    .foregroundStyle(Color.evSecondaryText)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Appearance")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.evPrimaryText)
                    Picker("Appearance", selection: $settingsVM.settings.appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Theme")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            } footer: {
                Text("Switch between Day and Dark mode.")
                    .foregroundStyle(Color.evSecondaryText)
            }

            if let grow {
                Section {
                    Button {
                        let text = DataExportService.exportGrow(
                            grow,
                            waterUnit: settingsVM.settings.waterUnit,
                            temperatureUnit: settingsVM.settings.temperatureUnit
                        )
                        let safeName = grow.growName
                            .replacingOccurrences(of: " ", with: "_")
                            .replacingOccurrences(of: "/", with: "_")
                        exportFilename = "\(safeName)_data"
                        exportDocument = GrowExportDocument(text: text)
                        isShowingExport = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(grow.growName)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.evPrimaryText)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Text("\(grow.plants.count) plant\(grow.plants.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(Color.evSecondaryText)
                            }
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.evPrimaryBlue)
                        }
                    }
                    .accessibilityLabel("Export \(grow.growName) data")
                } header: {
                    Text("Download Data")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.evDeepNavy)
                        .textCase(nil)
                } footer: {
                    Text("Export grow data as a text file.")
                        .foregroundStyle(Color.evSecondaryText)
                }
            }

            Section {
                Button {
                    loadExampleData()
                } label: {
                    HStack {
                        Label("Load Example Data", systemImage: "tray.and.arrow.down")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.evPrimaryBlue)
                        Spacer()
                    }
                }
                .disabled(showExampleLoaded)
                .accessibilityLabel("Load example grow with sample watering data")
            } header: {
                Text("Example Data")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            } footer: {
                Text(showExampleLoaded
                     ? "Example data loaded."
                     : "Creates a sample grow with watering history to explore the app.")
                    .foregroundStyle(Color.evSecondaryText)
            }

            Section {
                HStack {
                    Spacer()
                    Button("Reset Settings") {
                        settingsVM.reset()
                    }
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.evPrimaryBlue)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .stroke(Color.evPrimaryBlue, lineWidth: 1.5)
                    )
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section {
                HStack {
                    Spacer()
                    Text(appVersionText)
                        .font(.footnote)
                        .foregroundStyle(Color.evSlateGray)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.evBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
                    .fontWeight(.bold)
            }
        }
        .onChange(of: settingsVM.settings) { _, _ in
            settingsVM.save()
        }
        .fileExporter(
            isPresented: $isShowingExport,
            document: exportDocument,
            contentType: .plainText,
            defaultFilename: exportFilename
        ) { _ in
            exportDocument = nil
        }
    }

    // MARK: - Example Data

    private func loadExampleData() {
        let grow = Grow(growName: "Example Grow")
        modelContext.insert(grow)

        let plant = Plant(
            plantName: "Example Plant",
            potSize: "6 inch",
            mediumType: "soil",
            maxRetentionCapacity: 1.6,
            goalRunoffPercent: 15.0,
            grow: grow
        )
        modelContext.insert(plant)

        let calendar = Calendar.current
        let logData: [(month: Int, day: Int, hour: Int, minute: Int, water: Double, runoff: Double, tempF: Double, humidity: Double)] = [
            (2, 10, 8, 45, 1.50, 0.19, 76.0, 13.0),
            (2, 12, 9, 24, 1.25, 0.32, 81.0, 18.0),
            (2, 14, 10, 30, 1.25, 0.32, 82.0, 18.0),
            (2, 16, 18, 36, 1.00, 0.32, 84.0, 20.0),
            (2, 18, 16, 48, 0.89, 0.19, 79.0, 24.0),
            (2, 21, 11, 6, 1.00, 0.10, 83.0, 33.0)
        ]

        for entry in logData {
            let components = DateComponents(year: 2026, month: entry.month, day: entry.day, hour: entry.hour, minute: entry.minute)
            let date = calendar.date(from: components) ?? Date()
            let tempC = UnitConversionService.toCelsius(entry.tempF, from: .fahrenheit)
            let log = WateringLog(
                waterAdded: entry.water,
                runoffCollected: entry.runoff,
                dateTime: date,
                temperatureCelsius: tempC,
                humidityPercent: entry.humidity
            )
            log.plant = plant
            modelContext.insert(log)
        }

        // Recalculate interval hours
        let allLogs = plant.wateringLogs
        WateringCalculationService.recalculateIntervalHours(for: allLogs)

        try? modelContext.save()
        HapticService.success()
        showExampleLoaded = true
    }
}
