// © 2026 Evapotrack. All rights reserved.
// AddWateringLogViewModel.swift
// Evapotrack
//
// Form state and validation for adding a new WateringLog.
// Logs are immutable after creation.
// User enters water/runoff in display unit and temperature in
// display temp unit; all values are converted to internal units
// (liters, Celsius) before storage. No rounding on stored values.

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class AddWateringLogViewModel {

    // MARK: - Form State

    var waterAddedText = ""
    var runoffCollectedText = ""
    var dateTime = Date()
    var temperatureText = ""
    var humidityText = ""
    var validationError: String?
    var showSaveConfirmation = false

    // MARK: - Dependencies

    nonisolated(unsafe) let plant: Plant
    private var logService: WateringLogService?
    private let dateProvider: DateProviding
    var waterUnit: WaterUnit = .liters
    var temperatureUnit: TemperatureUnit = .celsius

    nonisolated init(plant: Plant, dateProvider: DateProviding = SystemDateProvider()) {
        self.plant = plant
        self.dateProvider = dateProvider
    }

    func configure(modelContext: ModelContext, waterUnit: WaterUnit, temperatureUnit: TemperatureUnit) {
        guard logService == nil else { return }
        self.logService = WateringLogService(modelContext: modelContext)
        self.waterUnit = waterUnit
        self.temperatureUnit = temperatureUnit
    }

    /// Resets transient state so the form is clean if the sheet is re-presented.
    func resetState() {
        showSaveConfirmation = false
        validationError = nil
    }

    // MARK: - Actions

    func validate() -> Bool {
        validationError = nil

        guard let displayWater = Double(waterAddedText) else {
            validationError = Strings.waterAddedMustBeNumber
            return false
        }

        // Convert display → internal (liters) for validation
        let waterLiters = UnitConversionService.toLiters(displayWater, from: waterUnit)

        let waterResult = ValidationService.validateWaterAdded(waterLiters)
        if !waterResult.isValid { validationError = waterResult.errorMessage; return false }

        guard let displayRunoff = Double(runoffCollectedText) else {
            validationError = Strings.runoffMustBeNumber
            return false
        }

        let runoffLiters = UnitConversionService.toLiters(displayRunoff, from: waterUnit)

        let runoffResult = ValidationService.validateRunoff(runoffLiters, waterAdded: waterLiters)
        if !runoffResult.isValid { validationError = runoffResult.errorMessage; return false }

        // Retained cannot exceed 105% of Max Retention Capacity
        let retained = waterLiters - runoffLiters
        let retainedCap = plant.maxRetentionCapacity * AppConstants.maxRetainedFactor
        if retained > retainedCap {
            validationError = Strings.retainedExceedsCapacity
            return false
        }

        let dateResult = ValidationService.validateDate(dateTime, now: dateProvider.now)
        if !dateResult.isValid { validationError = dateResult.errorMessage; return false }

        // Prevent duplicate timestamps (compared to the minute)
        let calendar = Calendar.current
        let newMinute = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dateTime)
        let hasDuplicate = plant.wateringLogs.contains { log in
            calendar.dateComponents([.year, .month, .day, .hour, .minute], from: log.dateTime) == newMinute
        }
        if hasDuplicate {
            validationError = Strings.duplicateLogTimestamp
            return false
        }

        // Temperature is optional — only validate if the user entered a value
        if !temperatureText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let displayTemp = Double(temperatureText) else {
                validationError = Strings.temperatureMustBeNumber
                return false
            }
            let celsius = UnitConversionService.toCelsius(displayTemp, from: temperatureUnit)
            let tempResult = ValidationService.validateTemperature(celsius)
            if !tempResult.isValid { validationError = tempResult.errorMessage; return false }
        }

        // Humidity is optional — only validate if the user entered a value
        if !humidityText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let humidity = Double(humidityText) else {
                validationError = Strings.humidityMustBeNumber
                return false
            }
            let humResult = ValidationService.validateHumidity(humidity)
            if !humResult.isValid { validationError = humResult.errorMessage; return false }
        }

        return true
    }

    func save() -> Bool {
        guard !showSaveConfirmation else { return false }
        guard validate() else { return false }
        guard let displayWater = Double(waterAddedText),
              let displayRunoff = Double(runoffCollectedText) else { return false }
        guard let service = logService else {
            validationError = Strings.unableToSave
            return false
        }

        // Convert to internal units — store unrounded
        let waterLiters = UnitConversionService.toLiters(displayWater, from: waterUnit)
        let runoffLiters = UnitConversionService.toLiters(displayRunoff, from: waterUnit)

        let tempCelsius: Double? = {
            guard let displayTemp = Double(temperatureText) else { return nil }
            return UnitConversionService.toCelsius(displayTemp, from: temperatureUnit)
        }()

        let humidity: Double? = Double(humidityText)

        let log = WateringLog(
            waterAdded: waterLiters,
            runoffCollected: runoffLiters,
            dateTime: dateTime,
            temperatureCelsius: tempCelsius,
            humidityPercent: humidity
        )

        do {
            try service.addLog(log, to: plant)
        } catch {
            validationError = Strings.failedToSave
            return false
        }
        showSaveConfirmation = true
        return true
    }
}
