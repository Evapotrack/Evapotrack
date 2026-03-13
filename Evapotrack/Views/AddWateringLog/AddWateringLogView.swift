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
    @State private var vm: AddWateringLogViewModel
    @State private var isShowingHowTo = false
    @State private var dismissTask: Task<Void, Never>?

    init(plant: Plant) {
        _vm = State(wrappedValue: AddWateringLogViewModel(plant: plant))
    }

    private var waterUnit: WaterUnit { settingsVM.settings.waterUnit }
    private var tempUnit: TemperatureUnit { settingsVM.settings.temperatureUnit }

    var body: some View {
        Form {
            Section {
                TextField(
                    "Water Added (\(waterUnit.abbreviation))",
                    text: $vm.waterAddedText
                )
                .keyboardType(.decimalPad)
                .textLimit($vm.waterAddedText, maxLength: AppConstants.maxNumericInputLength)
                .accessibilityLabel("Water Added in \(waterUnit.abbreviation)")

                TextField(
                    "Runoff Collected (\(waterUnit.abbreviation))",
                    text: $vm.runoffCollectedText
                )
                .keyboardType(.decimalPad)
                .textLimit($vm.runoffCollectedText, maxLength: AppConstants.maxNumericInputLength)
                .accessibilityLabel("Runoff Collected in \(waterUnit.abbreviation)")
            } header: {
                Text("Water")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            }

            Section {
                DatePicker("Date", selection: $vm.dateTime, in: ...Date.now, displayedComponents: .date)
                DatePicker("Time", selection: $vm.dateTime, in: ...Date.now, displayedComponents: .hourAndMinute)
            } header: {
                Text("Date & Time")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            }

            Section {
                TextField(
                    "Temperature (\(tempUnit.abbreviation), optional)",
                    text: $vm.temperatureText
                )
                .keyboardType(.decimalPad)
                .textLimit($vm.temperatureText, maxLength: AppConstants.maxNumericInputLength)
                .accessibilityLabel("Temperature in \(tempUnit.abbreviation)")
                .accessibilityHint("Optional")

                TextField("Humidity (%, optional)", text: $vm.humidityText)
                    .keyboardType(.decimalPad)
                    .textLimit($vm.humidityText, maxLength: AppConstants.maxNumericInputLength)
                    .accessibilityLabel("Humidity percent")
                    .accessibilityHint("Optional")
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
                    if vm.save() {
                        HapticService.success()
                        dismissTask = Task {
                            try? await Task.sleep(for: .seconds(1))
                            dismiss()
                        }
                    }
                }
                .font(.body)
                .fontWeight(.bold)
                .disabled(vm.showSaveConfirmation)
            }
        }
        .navigationDestination(isPresented: $isShowingHowTo) {
            HowToView(context: .addWatering)
        }
        .onAppear {
            vm.resetState()
            vm.configure(
                modelContext: modelContext,
                waterUnit: waterUnit,
                temperatureUnit: tempUnit
            )
        }
        .overlay {
            if vm.showSaveConfirmation {
                Color.evInkBlack.opacity(0.2)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(.evPrimaryBlue)
                            Text("Saved")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color.evPrimaryText)
                        }
                        .padding(28)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.evBackground)
                                .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    .allowsHitTesting(false)
                    .accessibilityAddTraits(.isModal)
                    .accessibilityLabel("Saved")
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.showSaveConfirmation)
        .onDisappear { dismissTask?.cancel() }
    }
}
