// CreatePlantView.swift
// Evapotrack
//
// Form for creating a new plant. Plants are immutable after creation.
// Max retention capacity is entered in the user's display water unit
// and converted to liters (internal) on save.
// Includes a calculator to derive max retention from water added
// and runoff collected.

import SwiftUI

struct CreatePlantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SettingsViewModel.self) private var settingsVM
    @State private var vm = CreatePlantViewModel()
    var grow: Grow? = nil

    private var waterUnit: WaterUnit { settingsVM.settings.waterUnit }

    var body: some View {
        Form {
            Section {
                TextField("Plant Name", text: $vm.plantName)
                    .autocorrectionDisabled()
                    .textLimit($vm.plantName, maxLength: AppConstants.maxPlantNameLength)

                TextField("Pot Size (e.g. 6 inch, 1 gallon)", text: $vm.potSize)
                    .textLimit($vm.potSize, maxLength: AppConstants.maxDescriptionLength)

                TextField("Medium Type (e.g. soil, perlite)", text: $vm.mediumType)
                    .textLimit($vm.mediumType, maxLength: AppConstants.maxDescriptionLength)
            } header: {
                Text("Plant Info")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            }

            Section {
                TextField(
                    "Max Retention Capacity (\(DisplayFormatter.waterUnitHint(waterUnit)))",
                    text: $vm.maxRetentionCapacityText
                )
                .keyboardType(.decimalPad)
                .textLimit($vm.maxRetentionCapacityText, maxLength: AppConstants.maxNumericInputLength)

                Text("The maximum volume of water the medium can hold before runoff begins.")
                    .font(.callout)
                    .foregroundStyle(Color.evSecondaryText)
            } header: {
                Text("Capacity")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            }

            Section {
                DisclosureGroup("Calculator") {
                    TextField(
                        "Water Added (\(DisplayFormatter.waterUnitHint(waterUnit)))",
                        text: $vm.calculatorWaterAddedText
                    )
                    .keyboardType(.decimalPad)
                    .textLimit($vm.calculatorWaterAddedText, maxLength: AppConstants.maxNumericInputLength)

                    TextField(
                        "Runoff Collected (\(DisplayFormatter.waterUnitHint(waterUnit)))",
                        text: $vm.calculatorRunoffText
                    )
                    .keyboardType(.decimalPad)
                    .textLimit($vm.calculatorRunoffText, maxLength: AppConstants.maxNumericInputLength)

                    HStack(spacing: 12) {
                        Button("Calculate") {
                            vm.calculate()
                        }
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.evPrimaryBlue))

                        Button("Clear") {
                            vm.clearCalculator()
                        }
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.evSlateGray)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .stroke(Color.evSlateGray, lineWidth: 1.5)
                        )
                    }

                    if let error = vm.calculatorError {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }
            } footer: {
                Text("Don't know your capacity? Use the calculator to derive it from a test watering.")
                    .foregroundStyle(Color.evSecondaryText)
            }

            Section {
                TextField("Example: 15%", text: $vm.goalRunoffPercentText)
                    .keyboardType(.decimalPad)
                    .textLimit($vm.goalRunoffPercentText, maxLength: AppConstants.maxNumericInputLength)

                Text("The runoff percentage the Next algorithm will target. Defaults to 15% if left blank.")
                    .font(.callout)
                    .foregroundStyle(Color.evSecondaryText)
            } header: {
                Text("Goal Runoff %")
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
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .background(Color.evBackground)
        .navigationTitle("Add Plant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .fontWeight(.bold)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if vm.save() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            dismiss()
                        }
                    }
                }
                .fontWeight(.bold)
                .disabled(vm.showSaveConfirmation)
            }
        }
        .onAppear {
            vm.configure(modelContext: modelContext, waterUnit: waterUnit, grow: grow)
        }
        .overlay {
            if vm.showSaveConfirmation {
                Color.evInkBlack.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(.evPrimaryBlue)
                            .transition(.scale.combined(with: .opacity))
                    }
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.showSaveConfirmation)
    }
}
