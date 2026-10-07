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

    /// Bounds in the message are shown in the user's water unit.
    static func validateMaxRetention(_ liters: Double, unit: WaterUnit = .liters) -> ValidationResult {
        let range = AppConstants.maxRetentionCapacityRange
        return Validators.isValidMaxRetention(liters)
            ? .valid
            : .invalid(Strings.maxRetentionRange(
                min: DisplayFormatter.waterLimit(range.lowerBound, unit: unit, roundingUp: true),
                max: DisplayFormatter.waterLimit(range.upperBound, unit: unit, roundingUp: false)
            ))
    }

    /// Bounds in the message are shown in the user's water unit.
    static func validateWaterAdded(_ liters: Double, unit: WaterUnit = .liters) -> ValidationResult {
        let range = AppConstants.waterAddedRange
        return Validators.isValidVolume(liters)
            ? .valid
            : .invalid(Strings.waterAddedRange(
                min: DisplayFormatter.waterLimit(range.lowerBound, unit: unit, roundingUp: true),
                max: DisplayFormatter.waterLimit(range.upperBound, unit: unit, roundingUp: false)
            ))
    }

    static func validateRunoff(_ runoff: Double, waterAdded: Double) -> ValidationResult {
        Validators.isValidRunoff(runoff, waterAdded: waterAdded)
            ? .valid
            : .invalid(Strings.runoffRange)
    }

    /// Bounds in the message are shown in the user's temperature unit.
    static func validateTemperature(_ celsius: Double, unit: TemperatureUnit = .celsius) -> ValidationResult {
        let range = AppConstants.temperatureRangeCelsius
        return Validators.isValidTemperature(celsius)
            ? .valid
            : .invalid(Strings.temperatureRange(
                min: DisplayFormatter.temperature(range.lowerBound, unit: unit),
                max: DisplayFormatter.temperature(range.upperBound, unit: unit)
            ))
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
