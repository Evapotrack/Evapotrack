// SettingsView.swift
// Evapotrack
//
// Settings screen for language, water and temperature display units,
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

    private var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Evapotrack v\(version) (\(build))"
    }

    var body: some View {
        @Bindable var settingsVM = settingsVM
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(Strings.waterUnit)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.evPrimaryText)
                    Picker(Strings.waterUnit, selection: $settingsVM.settings.waterUnit) {
                        ForEach(WaterUnit.allCases) { unit in
                            Text(unit.abbreviation).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text(Strings.temperatureUnit)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.evPrimaryText)
                    Picker(Strings.temperatureUnit, selection: $settingsVM.settings.temperatureUnit) {
                        ForEach(TemperatureUnit.allCases) { unit in
                            Text(unit.abbreviation).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text(Strings.appearance)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.evPrimaryText)
                    Picker(Strings.appearance, selection: $settingsVM.settings.appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 2)
            } header: {
                Text(Strings.displayUnits)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            } footer: {
                Text(Strings.displayUnitsFooter)
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
                                Text(Strings.plantCount(grow.plants.count))
                                    .font(.caption)
                                    .foregroundStyle(Color.evSecondaryText)
                            }
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.evPrimaryBlue)
                        }
                    }
                    .accessibilityLabel(Strings.exportGrowData(grow.growName))
                } header: {
                    Text(Strings.downloadData)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.evDeepNavy)
                        .textCase(nil)
                } footer: {
                    Text(Strings.exportFooter)
                        .foregroundStyle(Color.evSecondaryText)
                }
            }

            if grow == nil {
                Section {
                    HStack {
                        Text(Strings.language)
                            .font(.subheadline)
                            .foregroundStyle(Color.evSecondaryText)
                        Spacer()
                        Picker(Strings.language, selection: $settingsVM.settings.language) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }
                }
            }

            Section {
                HStack {
                    Spacer()
                    Button(Strings.resetSettings) {
                        settingsVM.reset()
                    }
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.evPrimaryBlue)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
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
        .id(settingsVM.settings.language)
        .scrollContentBackground(.hidden)
        .background(Color.evBackground)
        .navigationTitle(Strings.settings)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(Strings.done) { dismiss() }
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
