// © 2026 Evapotrack. All rights reserved.
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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var waterUnit: WaterUnit { settingsVM.settings.waterUnit }
    private var tempUnit: TemperatureUnit { settingsVM.settings.temperatureUnit }
    private var sectionHeaderFont: Font {
        horizontalSizeClass == .regular ? .headline.weight(.bold) : .title2.weight(.bold)
    }

    var body: some View {
        Form {
            Section {
                TextField(
                    Strings.waterAddedField(waterUnit.abbreviation),
                    text: $vm.waterAddedText
                )
                .keyboardType(.decimalPad)
                .textLimit($vm.waterAddedText, maxLength: AppConstants.maxNumericInputLength)
                .accessibilityLabel(Strings.waterAddedAccessibility(waterUnit.abbreviation))

                TextField(
                    Strings.runoffCollectedField(waterUnit.abbreviation),
                    text: $vm.runoffCollectedText
                )
                .keyboardType(.decimalPad)
                .textLimit($vm.runoffCollectedText, maxLength: AppConstants.maxNumericInputLength)
                .accessibilityLabel(Strings.runoffCollectedAccessibility(waterUnit.abbreviation))
            } header: {
                Text(Strings.water)
                    .font(sectionHeaderFont)
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            }

            Section {
                DatePicker(Strings.date, selection: $vm.dateTime, in: ...Date.now, displayedComponents: .date)
                DatePicker(Strings.time, selection: $vm.dateTime, in: ...Date.now, displayedComponents: .hourAndMinute)
            } header: {
                Text(Strings.dateAndTime)
                    .font(sectionHeaderFont)
                    .foregroundStyle(.evDeepNavy)
                    .textCase(nil)
            }

            Section {
                TextField(
                    Strings.temperatureField(tempUnit.abbreviation),
                    text: $vm.temperatureText
                )
                .keyboardType(.decimalPad)
                .textLimit($vm.temperatureText, maxLength: AppConstants.maxNumericInputLength)
                .accessibilityLabel(Strings.temperatureAccessibility(tempUnit.abbreviation))
                .accessibilityHint(Strings.optional)

                TextField(Strings.humidityField, text: $vm.humidityText)
                    .keyboardType(.decimalPad)
                    .textLimit($vm.humidityText, maxLength: AppConstants.maxNumericInputLength)
                    .accessibilityLabel(Strings.humidityPercent)
                    .accessibilityHint(Strings.optional)
            } header: {
                Text(Strings.environment)
                    .font(sectionHeaderFont)
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
                .accessibilityLabel(Strings.helpLabel)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .background(Color.evBackground)
        .navigationTitle(Strings.addWateringEvent)
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
