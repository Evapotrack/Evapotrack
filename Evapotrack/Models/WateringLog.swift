// WateringLog.swift
// Evapotrack
//
// SwiftData model representing a single watering event.
// Immutable after creation — logs may be created or deleted
// but never edited by the user. System-driven recalculations
// (intervalHours) are the only permitted mutations.
//
// All values stored in internal units (liters, Celsius).
// All stored values are unrounded; rounding is display-only.

import Foundation
import SwiftData

@Model
final class WateringLog {

    // MARK: - Identity

    var id: UUID

    // MARK: - User-Entered Fields

    /// Volume of water added, in liters. Must be > 0.
    var waterAdded: Double

    /// Volume of runoff collected, in liters. Must be ≥ 0 and < waterAdded.
    var runoffCollected: Double

    /// Date and time the watering occurred.
    var dateTime: Date

    /// Ambient temperature at time of watering, in Celsius (optional).
    var temperatureCelsius: Double?

    /// Relative humidity at time of watering, 0–100 (optional).
    var humidityPercent: Double?

    // MARK: - Calculated Fields (stored unrounded)

    /// Water retained by the medium: waterAdded - runoffCollected.
    var retained: Double

    /// Runoff as a percentage of water added: (runoffCollected / waterAdded) × 100.
    var runoffPercent: Double

    /// Hours since the previous watering log for the same plant.
    /// nil for the chronologically first log.
    /// Recalculated by the system when logs are added or deleted.
    var intervalHours: Double?

    // MARK: - Relationships

    var plant: Plant?

    // MARK: - Init

    init(
        id: UUID = UUID(),
        waterAdded: Double,
        runoffCollected: Double,
        dateTime: Date,
        temperatureCelsius: Double? = nil,
        humidityPercent: Double? = nil,
        intervalHours: Double? = nil,
        plant: Plant? = nil
    ) {
        self.id = id
        self.waterAdded = waterAdded
        self.runoffCollected = runoffCollected
        self.dateTime = dateTime
        self.temperatureCelsius = temperatureCelsius
        self.humidityPercent = humidityPercent
        self.plant = plant

        // Compute derived fields — stored unrounded
        self.retained = max(0, waterAdded - runoffCollected)
        self.runoffPercent = min((runoffCollected / waterAdded) * 100.0, 100.0)
        self.intervalHours = intervalHours
    }
}
