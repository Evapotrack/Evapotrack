// ValidationService.swift
// Evapotrack
//
// High-level validation that returns human-readable error messages.

import Foundation

enum ValidationResult: Equatable {
    case valid
    case invalid(String)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .invalid(let msg) = self { return msg }
        return nil
    }
}

enum ValidationService {

    static func validateGrowName(_ name: String) -> ValidationResult {
        Validators.isValidGrowName(name)
            ? .valid
            : .invalid("Grow name must be 1–\(AppConstants.maxGrowNameLength) characters and not blank.")
    }

    static func validatePlantName(_ name: String) -> ValidationResult {
        Validators.isValidPlantName(name)
            ? .valid
            : .invalid("Plant name must be 1–\(AppConstants.maxPlantNameLength) characters and not blank.")
    }

    static func validatePotSize(_ value: String) -> ValidationResult {
        Validators.isValidPotSize(value)
            ? .valid
            : .invalid("Pot size must not be blank.")
    }

    static func validateMediumType(_ value: String) -> ValidationResult {
        Validators.isValidMediumType(value)
            ? .valid
            : .invalid("Medium type must not be blank.")
    }

    static func validateMaxRetention(_ value: Double) -> ValidationResult {
        Validators.isValidMaxRetention(value)
            ? .valid
            : .invalid("Max retention capacity must be between 0.001 and 100 liters.")
    }

    static func validateWaterAdded(_ value: Double) -> ValidationResult {
        Validators.isValidVolume(value)
            ? .valid
            : .invalid("Water added must be between 0.001 and 100 liters.")
    }

    static func validateRunoff(_ runoff: Double, waterAdded: Double) -> ValidationResult {
        Validators.isValidRunoff(runoff, waterAdded: waterAdded)
            ? .valid
            : .invalid("Runoff must be ≥ 0 and less than water added.")
    }

    static func validateTemperature(_ value: Double) -> ValidationResult {
        Validators.isValidTemperature(value)
            ? .valid
            : .invalid("Temperature must be between -50 and 60 °C.")
    }

    static func validateHumidity(_ value: Double) -> ValidationResult {
        Validators.isValidHumidity(value)
            ? .valid
            : .invalid("Humidity must be between 0 and 100%.")
    }

    static func validateDate(_ date: Date, now: Date) -> ValidationResult {
        Validators.isNotFutureDate(date, now: now)
            ? .valid
            : .invalid("Date cannot be in the future.")
    }
}
