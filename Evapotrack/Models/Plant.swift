// Plant.swift
// Evapotrack
//
// SwiftData model representing a plant the user is tracking.
// Immutable after creation — plants may be created or deleted
// but never edited. Deleting a plant cascade-deletes all
// associated WateringLogs.

import Foundation
import SwiftData

@Model
final class Plant {

    // MARK: - Stored Fields

    /// Unique identifier.
    var id: UUID

    /// User-given name for the plant (required).
    var plantName: String

    /// Descriptive pot size (e.g. "6 inch", "1 gallon", "small").
    var potSize: String

    /// Growing medium type (e.g. "soil", "perlite", "coco coir").
    var mediumType: String

    /// Maximum water the medium can hold before runoff, in liters.
    /// Must always be greater than 0. Stored unrounded.
    var maxRetentionCapacity: Double

    /// User-set goal runoff percentage used by the Next algorithm.
    /// Defaults to 15.0 if not specified during plant creation.
    var goalRunoffPercent: Double = 15.0

    /// Date the plant was created.
    var createdAt: Date = Date()

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade, inverse: \WateringLog.plant)
    var wateringLogs: [WateringLog]

    /// The grow group this plant belongs to.
    var grow: Grow?

    // MARK: - Init

    init(
        id: UUID = UUID(),
        plantName: String,
        potSize: String,
        mediumType: String,
        maxRetentionCapacity: Double,
        goalRunoffPercent: Double = AppConstants.targetRunoffPercent,
        createdAt: Date = Date(),
        grow: Grow? = nil
    ) {
        self.id = id
        self.plantName = plantName
        self.potSize = potSize
        self.mediumType = mediumType
        self.maxRetentionCapacity = maxRetentionCapacity
        // Clamp to valid range — prevents division by zero in recommendation algorithm
        self.goalRunoffPercent = min(max(goalRunoffPercent, 0.1), 99.9)
        self.createdAt = createdAt
        self.wateringLogs = []
        self.grow = grow
    }
}
