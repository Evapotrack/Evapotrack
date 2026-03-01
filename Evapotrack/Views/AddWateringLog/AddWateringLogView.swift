// AddWateringLogView.swift
// Evapotrack
//
// Form for adding a new watering log. Logs are immutable after creation.
// User enters water/runoff in display unit and temperature in display
// temp unit. All values converted to internal units on save.

import SwiftUI

struct AddWateringLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsViewModel.self) private var settingsVM
    @FocusState private var isFieldFocused: Bool
    @State private var vm: AddWateringLogViewModel
    @State private var isShowingHowTo = false

    init(plant: Plant) {
        _vm = State(wrappedValue: AddWateringLogViewModel(plant: plant))
    }

    private var waterUnit: WaterUnit { settingsVM.settings.waterUnit }
    private var tempUnit: TemperatureUnit { settingsVM.settings.temperatureUnit }

    var body: some View {
        Form {
            Section {
                TextField(
                    "Water Added (\(DisplayFormatter.waterUnitHint(waterUnit)))",
                    text: $vm.waterAddedText
                )
                .keyboardType(.decimalPad)
                .focused($isFieldFocused)

                TextField(
                    "Runoff Collected (\(DisplayFormatter.waterUnitHint(waterUnit)))",
                    text: $vm.runoffCollectedText
                )
                .keyboardType(.decimalPad)
            } header: {
                Text("Water")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            }

            Section {
                DatePicker("Date", selection: $vm.dateTime, in: ...Date.now, displayedComponents: .date)
                DatePicker("Time", selection: $vm.dateTime, displayedComponents: .hourAndMinute)
            } header: {
                Text("Date & Time")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            }

            Section {
                TextField(
                    "Temperature (\(DisplayFormatter.tempUnitHint(tempUnit)), optional)",
                    text: $vm.temperatureText
                )
                .keyboardType(.decimalPad)

                TextField("Humidity (%, optional)", text: $vm.humidityText)
                    .keyboardType(.decimalPad)
            } header: {
                Text("Environment")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            }

            if let error = vm.validationError {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }

            Section {
                Button {
                    isShowingHowTo = true
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.evPrimaryBlue)
                            .clipShape(Circle())
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Help")
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .background(Color.evBackground)
        .navigationTitle("Add Watering Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .font(.body)
                    .fontWeight(.bold)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if vm.save() { dismiss() }
                }
                .font(.body)
                .fontWeight(.bold)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isFieldFocused = false }
                    .fontWeight(.semibold)
            }
        }
        .navigationDestination(isPresented: $isShowingHowTo) {
            HowToView(context: .addWatering)
        }
        .onAppear {
            vm.configure(
                modelContext: modelContext,
                waterUnit: waterUnit,
                temperatureUnit: tempUnit
            )
        }
    }
}
