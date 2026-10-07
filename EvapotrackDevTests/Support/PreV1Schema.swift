// © 2026 Evapotrack. All rights reserved.
// PreV1Schema.swift
// EvapotrackDevTests
//
// A hypothetical older model that matches no schema version in the
// migration plan (Plant has no goalRunoffPercent or createdAt). Used to
// prove the store still opens through the automatic-migration fallback.

import Foundation
import SwiftData

enum PreV1Schema {

    @Model
    final class Grow {
        @Attribute(.unique) var id: UUID
        var growName: String
        var createdAt: Date
        @Relationship(deleteRule: .cascade, inverse: \Plant.grow)
        var plants: [Plant]

        init(id: UUID, growName: String, createdAt: Date) {
            self.id = id
            self.growName = growName
            self.createdAt = createdAt
            self.plants = []
        }
    }

    @Model
    final class Plant {
        @Attribute(.unique) var id: UUID
        var plantName: String
        var potSize: String
        var mediumType: String
        var maxRetentionCapacity: Double
        @Relationship(deleteRule: .cascade, inverse: \WateringLog.plant)
        var wateringLogs: [WateringLog]
        var grow: Grow?

        init(id: UUID, plantName: String, potSize: String, mediumType: String, maxRetentionCapacity: Double, grow: Grow?) {
            self.id = id
            self.plantName = plantName
            self.potSize = potSize
            self.mediumType = mediumType
            self.maxRetentionCapacity = maxRetentionCapacity
            self.wateringLogs = []
            self.grow = grow
        }
    }

    @Model
    final class WateringLog {
        @Attribute(.unique) var id: UUID
        var waterAdded: Double
        var runoffCollected: Double
        var dateTime: Date
        var temperatureCelsius: Double?
        var humidityPercent: Double?
        var retained: Double
        var runoffPercent: Double
        var intervalHours: Double?
        @Relationship var plant: Plant?

        init(id: UUID, waterAdded: Double, runoffCollected: Double, dateTime: Date, plant: Plant?) {
            self.id = id
            self.waterAdded = waterAdded
            self.runoffCollected = runoffCollected
            self.dateTime = dateTime
            self.temperatureCelsius = nil
            self.humidityPercent = nil
            self.retained = waterAdded - runoffCollected
            self.runoffPercent = runoffCollected / waterAdded * 100
            self.intervalHours = nil
            self.plant = plant
        }
    }
}
