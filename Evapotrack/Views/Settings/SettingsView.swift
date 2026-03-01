// SettingsView.swift
// Evapotrack
//
// Settings screen for water and temperature display units.
// Uses segmented pickers with exact terminology.
// Changes persist immediately via auto-save — no stored
// SwiftData values are ever modified.

import SwiftUI

struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var settingsVM
    @Environment(\.dismiss) private var dismiss

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
                        .font(.callout)
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
                        .font(.callout)
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
                        .font(.callout)
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
                HStack {
                    Spacer()
                    Button("Reset") {
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
                    .fontWeight(.bold)
            }
        }
        .onChange(of: settingsVM.settings) { _, _ in
            settingsVM.save()
        }
    }
}
