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
    @State private var dismissTask: Task<Void, Never>?
    var grow: Grow? = nil

    private var waterUnit: WaterUnit { settingsVM.settings.waterUnit }

    var body: some View {
        Form {
            Section {
                TextField(Strings.plantName, text: $vm.plantName)
                    .autocorrectionDisabled()
                    .textLimit($vm.plantName, maxLength: AppConstants.maxPlantNameLength)
                    .accessibilityLabel(Strings.plantName)

                TextField(Strings.potSizePlaceholder, text: $vm.potSize)
                    .textLimit($vm.potSize, maxLength: AppConstants.maxPotSizeLength)
                    .accessibilityLabel(Strings.potSize)

                TextField(Strings.mediumTypePlaceholder, text: $vm.mediumType)
                    .textLimit($vm.mediumType, maxLength: AppConstants.maxMediumTypeLength)
                    .accessibilityLabel(Strings.mediumType)
            } header: {
                Text(Strings.plantInfo)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            }

            Section {
                TextField(
                    Strings.maxRetentionField(waterUnit.abbreviation),
                    text: $vm.maxRetentionCapacityText
                )
                .keyboardType(.decimalPad)
                .textLimit($vm.maxRetentionCapacityText, maxLength: AppConstants.maxNumericInputLength)
                .accessibilityLabel(Strings.maxRetentionAccessibility(waterUnit.abbreviation))

                Text(Strings.maxRetentionDescription)
                    .font(.callout)
                    .foregroundStyle(Color.evSecondaryText)
            } header: {
                Text(Strings.capacity)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            }

            Section {
                DisclosureGroup(Strings.calculator) {
                    TextField(
                        Strings.waterAddedField(waterUnit.abbreviation),
                        text: $vm.calculatorWaterAddedText
                    )
                    .keyboardType(.decimalPad)
                    .textLimit($vm.calculatorWaterAddedText, maxLength: AppConstants.maxNumericInputLength)
                    .accessibilityLabel(Strings.calcWaterAddedAccessibility(waterUnit.abbreviation))

                    TextField(
                        Strings.runoffCollectedField(waterUnit.abbreviation),
                        text: $vm.calculatorRunoffText
                    )
                    .keyboardType(.decimalPad)
                    .textLimit($vm.calculatorRunoffText, maxLength: AppConstants.maxNumericInputLength)
                    .accessibilityLabel(Strings.calcRunoffAccessibility(waterUnit.abbreviation))

                    HStack(spacing: 12) {
                        Button(Strings.calculate) {
                            vm.calculate()
                        }
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.evPrimaryBlue))
                        .accessibilityHint(Strings.calculateHint)

                        Button(Strings.clear) {
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
                Text(Strings.calculatorFooter)
                    .foregroundStyle(Color.evSecondaryText)
            }

            Section {
                TextField(Strings.goalRunoffPlaceholder, text: $vm.goalRunoffPercentText)
                    .keyboardType(.decimalPad)
                    .textLimit($vm.goalRunoffPercentText, maxLength: AppConstants.maxNumericInputLength)
                    .accessibilityLabel(Strings.goalRunoffPercent)

                Text(Strings.goalRunoffDescription)
                    .font(.callout)
                    .foregroundStyle(Color.evSecondaryText)
            } header: {
                Text(Strings.goalRunoffSection)
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
        .navigationTitle(Strings.addPlant)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Strings.cancel) { dismiss() }
                    .font(.body)
                    .fontWeight(.bold)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(Strings.save) {
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
        .onAppear {
            vm.resetState()
            vm.configure(modelContext: modelContext, waterUnit: waterUnit, grow: grow)
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
                            Text(Strings.saved)
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
                    .accessibilityLabel(Strings.savedLabel)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.showSaveConfirmation)
        .onDisappear { dismissTask?.cancel() }
    }
}
