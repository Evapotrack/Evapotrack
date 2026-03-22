// © 2026 Evapotrack. All rights reserved.
// Validators.swift
// Evapotrack
//
// Pure-function input validators used by ViewModels before
// persisting data. Centralizes all business rules so they
// can be tested independently of the UI.

import Foundation

enum Validators {

    // MARK: - Grow

    /// Grow name must be 1–50 non-whitespace-only characters.
    static func isValidGrowName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed.count <= AppConstants.maxGrowNameLength
    }

    // MARK: - Plant

    /// Plant name must be 1–50 non-whitespace-only characters.
    static func isValidPlantName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed.count <= AppConstants.maxPlantNameLength
    }

    /// Pot size description must not be blank.
    static func isValidPotSize(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Medium type description must not be blank.
    static func isValidMediumType(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Max retention capacity must be > 0.
    static func isValidMaxRetention(_ value: Double) -> Bool {
        AppConstants.maxRetentionCapacityRange.contains(value)
    }

    // MARK: - WateringLog

    /// Water added must be > 0.
    static func isValidVolume(_ value: Double) -> Bool {
        AppConstants.waterAddedRange.contains(value)
    }

    /// Runoff must be ≥ 0 and ≤ waterAdded.
    static func isValidRunoff(_ runoff: Double, waterAdded: Double) -> Bool {
        runoff >= 0 && runoff <= waterAdded
    }

    /// Temperature in Celsius must be within the allowed range.
    static func isValidTemperature(_ value: Double) -> Bool {
        AppConstants.temperatureRangeCelsius.contains(value)
    }

    /// Humidity must be 0–100.
    static func isValidHumidity(_ value: Double) -> Bool {
        AppConstants.humidityRange.contains(value)
    }

    // MARK: - Date

    /// Date must not be in the future.
    static func isNotFutureDate(_ date: Date, now: Date) -> Bool {
        date <= now
    }
}
