// © 2026 Evapotrack. All rights reserved.
// ValidationService.swift
// Evapotrack
//
// High-level validation that returns human-readable error messages.

import Foundation

nonisolated enum ValidationResult: Equatable, Sendable {
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
            : .invalid(Strings.growNameInvalid(AppConstants.maxGrowNameLength))
    }

    static func validatePlantName(_ name: String) -> ValidationResult {
        Validators.isValidPlantName(name)
            ? .valid
            : .invalid(Strings.plantNameInvalid(AppConstants.maxPlantNameLength))
    }

    static func validatePotSize(_ value: String) -> ValidationResult {
        Validators.isValidPotSize(value)
            ? .valid
            : .invalid(Strings.potSizeBlank)
    }

    static func validateMediumType(_ value: String) -> ValidationResult {
        Validators.isValidMediumType(value)
            ? .valid
            : .invalid(Strings.mediumTypeBlank)
    }

    static func validateMaxRetention(_ value: Double) -> ValidationResult {
        Validators.isValidMaxRetention(value)
            ? .valid
            : .invalid(Strings.maxRetentionRange)
    }

    static func validateWaterAdded(_ value: Double) -> ValidationResult {
        Validators.isValidVolume(value)
            ? .valid
            : .invalid(Strings.waterAddedRange)
    }

    static func validateRunoff(_ runoff: Double, waterAdded: Double) -> ValidationResult {
        Validators.isValidRunoff(runoff, waterAdded: waterAdded)
            ? .valid
            : .invalid(Strings.runoffRange)
    }

    static func validateTemperature(_ value: Double) -> ValidationResult {
        Validators.isValidTemperature(value)
            ? .valid
            : .invalid(Strings.temperatureRange)
    }

    static func validateHumidity(_ value: Double) -> ValidationResult {
        Validators.isValidHumidity(value)
            ? .valid
            : .invalid(Strings.humidityRange)
    }

    static func validateDate(_ date: Date, now: Date) -> ValidationResult {
        Validators.isNotFutureDate(date, now: now)
            ? .valid
            : .invalid(Strings.dateInFuture)
    }
}
