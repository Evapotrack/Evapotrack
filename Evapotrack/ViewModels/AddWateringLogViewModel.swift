// © 2026 Evapotrack. All rights reserved.
// AddWateringLogViewModel.swift
// Evapotrack
//
// Form state and validation for adding a new WateringLog.
// Logs are immutable after creation. Retaining more than the plant's
// Max Retention Capacity asks for confirmation instead of blocking.
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
    var isShowingCapacityConfirmation = false
    var capacityConfirmationMessage = ""

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
        isShowingCapacityConfirmation = false
    }

    // MARK: - Actions

    /// Validates the form. Hard errors set `validationError`. When the entry
    /// is otherwise valid but retains more than the plant's Max Retention
    /// Capacity (plus 5% measurement tolerance), asks for confirmation instead
    /// of rejecting it, unless `confirmedOverCapacity` is true.
    func validate(confirmedOverCapacity: Bool = false) -> Bool {
        validationError = nil

        guard let displayWater = NumericInput.parse(waterAddedText) else {
            validationError = Strings.waterAddedMustBeNumber
            return false
        }

        // Convert display → internal (liters) for validation
        let waterLiters = UnitConversionService.toLiters(displayWater, from: waterUnit)

        let waterResult = ValidationService.validateWaterAdded(waterLiters, unit: waterUnit)
        if !waterResult.isValid { validationError = waterResult.errorMessage; return false }

        guard let displayRunoff = NumericInput.parse(runoffCollectedText) else {
            validationError = Strings.runoffMustBeNumber
            return false
        }

        let runoffLiters = UnitConversionService.toLiters(displayRunoff, from: waterUnit)

        let runoffResult = ValidationService.validateRunoff(runoffLiters, waterAdded: waterLiters)
        if !runoffResult.isValid { validationError = runoffResult.errorMessage; return false }

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
            guard let displayTemp = NumericInput.parse(temperatureText) else {
                validationError = Strings.temperatureMustBeNumber
                return false
            }
            let celsius = UnitConversionService.toCelsius(displayTemp, from: temperatureUnit)
            let tempResult = ValidationService.validateTemperature(celsius, unit: temperatureUnit)
            if !tempResult.isValid { validationError = tempResult.errorMessage; return false }
        }

        // Humidity is optional — only validate if the user entered a value
        if !humidityText.trimmingCharacters(in: .whitespaces).isEmpty {
            guard let humidity = NumericInput.parse(humidityText) else {
                validationError = Strings.humidityMustBeNumber
                return false
            }
            let humResult = ValidationService.validateHumidity(humidity)
            if !humResult.isValid { validationError = humResult.errorMessage; return false }
        }

        // More retained than the plant's capacity usually means a typo, but it
        // can also mean the capacity is set too low. Ask; never block.
        let retained = waterLiters - runoffLiters
        let threshold = plant.maxRetentionCapacity * AppConstants.retainedConfirmationFactor
        if retained > threshold && !confirmedOverCapacity {
            capacityConfirmationMessage = Strings.retainedOverCapacityMessage(
                DisplayFormatter.water(retained, unit: waterUnit),
                capacity: DisplayFormatter.water(plant.maxRetentionCapacity, unit: waterUnit)
            )
            isShowingCapacityConfirmation = true
            return false
        }

        return true
    }

    func save(confirmedOverCapacity: Bool = false) -> Bool {
        guard !showSaveConfirmation else { return false }
        guard validate(confirmedOverCapacity: confirmedOverCapacity) else { return false }
        guard let displayWater = NumericInput.parse(waterAddedText),
              let displayRunoff = NumericInput.parse(runoffCollectedText) else { return false }
        guard let service = logService else {
            validationError = Strings.unableToSave
            return false
        }

        // Convert to internal units — store unrounded
        let waterLiters = UnitConversionService.toLiters(displayWater, from: waterUnit)
        let runoffLiters = UnitConversionService.toLiters(displayRunoff, from: waterUnit)

        let tempCelsius: Double? = {
            guard let displayTemp = NumericInput.parse(temperatureText) else { return nil }
            return UnitConversionService.toCelsius(displayTemp, from: temperatureUnit)
        }()

        let humidity: Double? = NumericInput.parse(humidityText)

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
