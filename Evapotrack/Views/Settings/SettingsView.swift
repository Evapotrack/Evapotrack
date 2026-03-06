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
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var settingsVM
    @Environment(\.dismiss) private var dismiss

    /// The grow to offer data export for. Nil when opened from GrowListView.
    var grow: Grow?

    @State private var isShowingExport = false
    @State private var exportDocument: GrowExportDocument?
    @State private var exportFilename = "data"

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
}
