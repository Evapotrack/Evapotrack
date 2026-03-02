// CreatePlantViewModel.swift
// Evapotrack
//
// Form state and validation for creating a new Plant.
// Plants are immutable after creation.
// User enters max retention capacity in their chosen display unit;
// value is converted to liters (internal) before storage.
// Includes a calculator to derive max retention from water added
// and runoff collected.

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class CreatePlantViewModel {

    // MARK: - Form State

    var plantName = ""
    var potSize = ""
    var mediumType = ""
    var maxRetentionCapacityText = ""
    var goalRunoffPercentText = ""
    var validationError: String?

    // MARK: - Calculator State

    var calculatorWaterAddedText = ""
    var calculatorRunoffText = ""
    var calculatorError: String?
    var showSaveConfirmation = false

    // MARK: - Picker Data

    static let suggestedPotSizes = ["Small", "Medium", "Large", "6 inch", "8 inch", "1 gallon", "3 gallon", "5 gallon"]
    static let suggestedMediumTypes = ["Soil", "Perlite", "Coco Coir", "LECA", "Sphagnum Moss", "Pumice", "Vermiculite"]

    // MARK: - Dependencies

    private var plantService: PlantService?
    var waterUnit: WaterUnit = .liters
    var grow: Grow?

    func configure(modelContext: ModelContext, waterUnit: WaterUnit, grow: Grow? = nil) {
        self.plantService = PlantService(modelContext: modelContext)
        self.waterUnit = waterUnit
        self.grow = grow
    }

    // MARK: - Actions

    func validate() -> Bool {
        validationError = nil

        let nameResult = ValidationService.validatePlantName(plantName)
        if !nameResult.isValid { validationError = nameResult.errorMessage; return false }

        let potResult = ValidationService.validatePotSize(potSize)
        if !potResult.isValid { validationError = potResult.errorMessage; return false }

        let mediumResult = ValidationService.validateMediumType(mediumType)
        if !mediumResult.isValid { validationError = mediumResult.errorMessage; return false }

        guard let displayValue = Double(maxRetentionCapacityText) else {
            validationError = "Max retention capacity must be a number."
            return false
        }

        // Convert from display unit to liters for validation
        let liters = UnitConversionService.toLiters(displayValue, from: waterUnit)

        let capacityResult = ValidationService.validateMaxRetention(liters)
        if !capacityResult.isValid { validationError = capacityResult.errorMessage; return false }

        // Goal Runoff % is optional — validate only if provided
        if !goalRunoffPercentText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let goalPercent = Double(goalRunoffPercentText) else {
                validationError = "Goal Runoff % must be a number."
                return false
            }
            guard goalPercent >= 0.1, goalPercent <= 99.9 else {
                validationError = "Goal Runoff % must be between 0.1 and 99.9."
                return false
            }
        }

        return true
    }

    func save() -> Bool {
        guard validate() else { return false }
        guard let displayValue = Double(maxRetentionCapacityText) else { return false }
        guard let service = plantService else {
            validationError = "Unable to save. Please try again."
            return false
        }

        // Convert to internal unit (liters) — store unrounded
        let liters = UnitConversionService.toLiters(displayValue, from: waterUnit)

        let goalPercent = Double(goalRunoffPercentText) ?? AppConstants.targetRunoffPercent

        let plant = Plant(
            plantName: plantName.trimmingCharacters(in: .whitespaces),
            potSize: potSize.trimmingCharacters(in: .whitespaces),
            mediumType: mediumType.trimmingCharacters(in: .whitespaces),
            maxRetentionCapacity: liters,
            goalRunoffPercent: goalPercent,
            grow: grow
        )

        service.addPlant(plant)
        showSaveConfirmation = true
        return true
    }

    // MARK: - Calculator

    func calculate() {
        calculatorError = nil

        // Parse water added
        guard let displayWater = Double(calculatorWaterAddedText) else {
            calculatorError = "Water added must be a number."
            return
        }

        // Convert to liters for validation
        let waterLiters = UnitConversionService.toLiters(displayWater, from: waterUnit)

        // Validate water added (0.001...100 liters)
        let waterResult = ValidationService.validateWaterAdded(waterLiters)
        if !waterResult.isValid {
            calculatorError = waterResult.errorMessage
            return
        }

        // Parse runoff
        guard let displayRunoff = Double(calculatorRunoffText) else {
            calculatorError = "Runoff collected must be a number."
            return
        }

        // Convert to liters
        let runoffLiters = UnitConversionService.toLiters(displayRunoff, from: waterUnit)

        // Calculator-specific: runoff must be > 0 (not ≥ 0 as in watering logs)
        guard runoffLiters > 0 else {
            calculatorError = "Runoff collected must be greater than 0."
            return
        }

        // Reuse existing runoff validation: runoff >= 0 && runoff < waterAdded
        let runoffResult = ValidationService.validateRunoff(runoffLiters, waterAdded: waterLiters)
        if !runoffResult.isValid {
            calculatorError = runoffResult.errorMessage
            return
        }

        // Calculate retained volume in liters
        let retainedLiters = waterLiters - runoffLiters

        // Convert back to display unit for the text field
        let displayRetained = UnitConversionService.fromLiters(retainedLiters, to: waterUnit)

        // Format with unit-appropriate precision
        maxRetentionCapacityText = String(
            format: "%.\(waterUnit.displayPrecision)f",
            displayRetained
        )
    }

    func clearCalculator() {
        calculatorWaterAddedText = ""
        calculatorRunoffText = ""
        calculatorError = nil
    }
}
