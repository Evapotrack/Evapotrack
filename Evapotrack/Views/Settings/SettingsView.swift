// SettingsView.swift
// Evapotrack
//
// Settings screen for water and temperature display units,
// appearance mode, and per-grow data export.
// Changes persist immediately via auto-save — no stored
// SwiftData values are ever modified.

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var settingsVM
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Grow.createdAt, order: .reverse) private var grows: [Grow]

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

            Section {
                if grows.isEmpty {
                    Text("No grows to export.")
                        .foregroundStyle(Color.evSecondaryText)
                } else {
                    ForEach(grows, id: \.id) { grow in
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
                    }
                }
            } header: {
                Text("Download Data")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            } footer: {
                Text("Export grow data as a text file.")
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
}
