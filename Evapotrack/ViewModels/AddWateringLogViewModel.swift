// © 2026 Evapotrack. All rights reserved.
// AddWateringLogViewModel.swift
// Evapotrack
//
// Form state and validation for adding a new WateringLog.
// Logs are immutable after creation. Retaining more than the plant's
// Max Retention Capacity asks for confirmation instead of blocking.
// An optional photo is prepared off the main actor as soon as it is picked
// and saved together with the log; an unsaved photo is discarded.
// User enters water/runoff in display unit and temperature in
// display temp unit; all values are converted to internal units
// (liters, Celsius) before storage. No rounding on stored values.

import Foundation
import SwiftData
import Observation
import OSLog

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

    // MARK: - Photo State

    enum PhotoState: Equatable {
        case empty
        case processing
        case ready(PreparedPhoto)
        case failed
    }

    var photoState: PhotoState = .empty

    var isProcessingPhoto: Bool { photoState == .processing }

    var preparedPhoto: PreparedPhoto? {
        if case .ready(let photo) = photoState { return photo }
        return nil
    }

    /// The photo being prepared; readable so tests can await it.
    @ObservationIgnored private(set) var photoTask: Task<Void, Never>?
    @ObservationIgnored private var photoRequestID: UUID?
    @ObservationIgnored private var didSave = false
    private let photoStore: PhotoStore

    // MARK: - Dependencies

    nonisolated(unsafe) let plant: Plant
    private var logService: WateringLogService?
    private let dateProvider: DateProviding
    var waterUnit: WaterUnit = .liters
    var temperatureUnit: TemperatureUnit = .celsius

    nonisolated init(
        plant: Plant,
        dateProvider: DateProviding = SystemDateProvider(),
        photoStore: PhotoStore = .shared
    ) {
        self.plant = plant
        self.dateProvider = dateProvider
        self.photoStore = photoStore
    }

    func configure(modelContext: ModelContext, waterUnit: WaterUnit, temperatureUnit: TemperatureUnit) {
        guard logService == nil else { return }
        self.logService = WateringLogService(modelContext: modelContext, photoStore: photoStore)
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
        guard !showSaveConfirmation, !isProcessingPhoto else { return false }
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
            try service.addLog(log, to: plant, photo: preparedPhoto)
        } catch {
            validationError = Strings.failedToSave
            return false
        }
        didSave = true
        showSaveConfirmation = true
        return true
    }

    // MARK: - Photo

    /// Prepares a picked photo off the main actor. `load` returns the picked
    /// file (the view passes PhotosPickerItem.loadTransferable). Picking again
    /// replaces the previous photo; a result that arrives after a newer pick
    /// or after the form closed is discarded.
    func loadPhoto(_ load: @escaping @Sendable () async throws -> PickedImageFile?) {
        photoTask?.cancel()
        discardPreparedPhoto()
        let requestID = UUID()
        photoRequestID = requestID
        photoState = .processing
        let store = photoStore

        photoTask = Task { [weak self] in
            do {
                guard let picked = try await load() else {
                    throw PhotoProcessor.ProcessingError.unreadableImage
                }
                let prepared = try await Task.detached(priority: .userInitiated) {
                    defer { try? FileManager.default.removeItem(at: picked.url) }
                    return try PhotoProcessor.process(
                        sourceURL: picked.url,
                        outputDirectory: try store.makeSessionIncomingDirectory()
                    )
                }.value
                guard let self, self.photoRequestID == requestID else {
                    store.discard(prepared)
                    return
                }
                self.photoState = .ready(prepared)
            } catch {
                guard let self, self.photoRequestID == requestID else { return }
                Logger.photos.error("Photo import failed: \(error.localizedDescription, privacy: .public)")
                self.photoState = .failed
            }
        }
    }

    /// Removes the photo from the form (before saving).
    func removePhoto() {
        photoTask?.cancel()
        photoRequestID = nil
        discardPreparedPhoto()
        photoState = .empty
    }

    /// Call when the form closes without saving: deletes a prepared photo.
    func discardUnsavedPhoto() {
        guard !didSave else { return }
        removePhoto()
    }

    private func discardPreparedPhoto() {
        if let photo = preparedPhoto {
            photoStore.discard(photo)
        }
    }
}
