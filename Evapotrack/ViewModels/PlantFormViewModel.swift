// © 2026 Evapotrack. All rights reserved.
// PlantFormViewModel.swift
// Evapotrack
//
// Form state and validation for creating a plant or editing an existing one.
// Max Retention Capacity is entered in the user's display water unit and
// stored in liters, unrounded. Values the app writes into a field (the
// calculator result, or the stored value when editing) are kept exactly
// unless the user changes the text, so nothing is rounded on the way to
// storage.
//
// The calculator derives Max Retention Capacity from a test watering of dry
// medium: water added − runoff collected.

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class PlantFormViewModel {

    enum Mode {
        case create(Grow?)
        case edit(Plant)
    }

    // MARK: - Form State

    var plantName = ""
    var potSize = ""
    var mediumType = ""
    var maxRetentionCapacityText = ""
    var goalRunoffPercentText = ""
    var validationError: String?
    var showSaveConfirmation = false

    // MARK: - Calculator State

    var calculatorWaterAddedText = ""
    var calculatorRunoffText = ""
    var calculatorError: String?

    // MARK: - Dependencies

    nonisolated(unsafe) let mode: Mode
    private var plantService: PlantService?
    var waterUnit: WaterUnit = .liters

    /// Exact liters behind the text the app last wrote into the capacity field.
    @ObservationIgnored private var capacitySource: (text: String, liters: Double)?
    /// The stored goal and the text it was shown as (edit mode).
    @ObservationIgnored private var goalSource: (text: String, percent: Double)?

    nonisolated init(mode: Mode) {
        self.mode = mode
    }

    var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var editedPlant: Plant? {
        if case .edit(let plant) = mode { return plant }
        return nil
    }

    private var grow: Grow? {
        switch mode {
        case .create(let grow): return grow
        case .edit(let plant): return plant.grow
        }
    }

    func configure(modelContext: ModelContext, waterUnit: WaterUnit) {
        guard plantService == nil else { return }
        self.plantService = PlantService(modelContext: modelContext)
        self.waterUnit = waterUnit

        if let plant = editedPlant {
            plantName = plant.plantName
            potSize = plant.potSize
            mediumType = plant.mediumType

            let capacityText = Self.fieldText(
                UnitConversionService.fromLiters(plant.maxRetentionCapacity, to: waterUnit),
                decimals: waterUnit.displayPrecision
            )
            maxRetentionCapacityText = capacityText
            capacitySource = (capacityText, plant.maxRetentionCapacity)

            let goal = plant.goalRunoffPercent
            let goalText = Self.fieldText(goal, decimals: goal.rounded() == goal ? 0 : 1)
            goalRunoffPercentText = goalText
            goalSource = (goalText, goal)
        }
    }

    /// Resets transient state so the form is clean if the sheet is re-presented.
    func resetState() {
        showSaveConfirmation = false
        validationError = nil
    }

    // MARK: - Actions

    func validate() -> Bool {
        validationError = nil

        let nameResult = ValidationService.validatePlantName(plantName)
        if !nameResult.isValid { validationError = nameResult.errorMessage; return false }

        // Plant names are unique within a grow (case-insensitive); a plant
        // being edited may keep its own name.
        if let grow {
            let trimmed = plantName.trimmingCharacters(in: .whitespaces).lowercased()
            let clash = grow.plants.contains { other in
                other !== editedPlant
                    && other.plantName.trimmingCharacters(in: .whitespaces).lowercased() == trimmed
            }
            if clash {
                validationError = Strings.plantNameDuplicate
                return false
            }
        }

        let potResult = ValidationService.validatePotSize(potSize)
        if !potResult.isValid { validationError = potResult.errorMessage; return false }

        let mediumResult = ValidationService.validateMediumType(mediumType)
        if !mediumResult.isValid { validationError = mediumResult.errorMessage; return false }

        guard let liters = capacityLiters() else {
            validationError = Strings.maxRetentionMustBeNumber
            return false
        }
        let capacityResult = ValidationService.validateMaxRetention(liters, unit: waterUnit)
        if !capacityResult.isValid { validationError = capacityResult.errorMessage; return false }

        switch goalEntry() {
        case .value:
            return true
        case .notANumber:
            validationError = Strings.goalRunoffMustBeNumber
            return false
        case .outOfRange:
            validationError = Strings.goalRunoffRange
            return false
        }
    }

    func save() -> Bool {
        guard !showSaveConfirmation else { return false }
        guard validate(),
              let liters = capacityLiters(),
              case .value(let goal) = goalEntry() else { return false }
        guard let service = plantService else {
            validationError = Strings.unableToSave
            return false
        }

        let name = plantName.trimmingCharacters(in: .whitespaces)
        let pot = potSize.trimmingCharacters(in: .whitespaces)
        let medium = mediumType.trimmingCharacters(in: .whitespaces)

        do {
            switch mode {
            case .create(let grow):
                try service.addPlant(Plant(
                    plantName: name,
                    potSize: pot,
                    mediumType: medium,
                    maxRetentionCapacity: liters,
                    goalRunoffPercent: goal,
                    grow: grow
                ))
            case .edit(let plant):
                try service.updatePlant(
                    plant,
                    name: name,
                    potSize: pot,
                    mediumType: medium,
                    maxRetentionCapacity: liters,
                    goalRunoffPercent: goal
                )
            }
        } catch {
            validationError = Strings.failedToSave
            return false
        }
        showSaveConfirmation = true
        return true
    }

    // MARK: - Calculator

    func calculate() {
        calculatorError = nil

        guard let displayWater = NumericInput.parse(calculatorWaterAddedText) else {
            calculatorError = Strings.waterAddedMustBeNumber
            return
        }
        let waterLiters = UnitConversionService.toLiters(displayWater, from: waterUnit)
        let waterResult = ValidationService.validateWaterAdded(waterLiters, unit: waterUnit)
        if !waterResult.isValid {
            calculatorError = waterResult.errorMessage
            return
        }

        guard let displayRunoff = NumericInput.parse(calculatorRunoffText) else {
            calculatorError = Strings.runoffMustBeNumber
            return
        }
        let runoffLiters = UnitConversionService.toLiters(displayRunoff, from: waterUnit)

        // The test watering must reach runoff (the medium is full) and must
        // not drain everything (nothing would have been retained).
        guard runoffLiters > 0 else {
            calculatorError = Strings.runoffMustBePositive
            return
        }
        guard runoffLiters < waterLiters else {
            calculatorError = Strings.calculatorRunoffTooLarge
            return
        }

        let retainedLiters = waterLiters - runoffLiters
        let text = Self.fieldText(
            UnitConversionService.fromLiters(retainedLiters, to: waterUnit),
            decimals: waterUnit.displayPrecision
        )
        maxRetentionCapacityText = text
        capacitySource = (text, retainedLiters)
    }

    func clearCalculator() {
        calculatorWaterAddedText = ""
        calculatorRunoffText = ""
        calculatorError = nil
    }

    // MARK: - Private

    private enum GoalEntry {
        case value(Double)
        case notANumber
        case outOfRange
    }

    /// Liters for the capacity field: the exact source value when the text is
    /// still what the app wrote, otherwise the typed value in liters.
    private func capacityLiters() -> Double? {
        if let source = capacitySource, source.text == maxRetentionCapacityText {
            return source.liters
        }
        guard let display = NumericInput.parse(maxRetentionCapacityText) else { return nil }
        return UnitConversionService.toLiters(display, from: waterUnit)
    }

    /// Goal runoff %: blank means the default; an unchanged stored value is
    /// kept even if it predates the current 5–50% range.
    private func goalEntry() -> GoalEntry {
        if let source = goalSource, source.text == goalRunoffPercentText {
            return .value(source.percent)
        }
        let trimmed = goalRunoffPercentText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return .value(AppConstants.targetRunoffPercent) }
        guard let percent = NumericInput.parse(trimmed) else { return .notANumber }
        guard AppConstants.goalRunoffPercentRange.contains(percent) else { return .outOfRange }
        return .value(percent)
    }

    private static func fieldText(_ value: Double, decimals: Int) -> String {
        String(format: "%.\(max(0, min(decimals, 6)))f", value)
    }
}
