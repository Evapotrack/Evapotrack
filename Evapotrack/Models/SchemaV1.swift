// © 2026 Evapotrack. All rights reserved.
// SchemaV1.swift
// Evapotrack
//
// FROZEN copy of the data model shipped through version 1.x, before schema
// versioning existed. SwiftData uses it to recognize stores written by those
// releases and migrate them to the current schema.
//
// Never edit these classes. Property names, types, optionality, default
// values, attributes and relationships must stay exactly as shipped, or
// existing stores will stop matching this version. Model changes go into a
// new schema version.

import Foundation
import SwiftData

nonisolated enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Grow.self, Plant.self, WateringLog.self]
    }
}

extension SchemaV1 {

    @Model
    nonisolated final class Grow {
        @Attribute(.unique) var id: UUID
        var growName: String
        var createdAt: Date

        @Relationship(deleteRule: .cascade, inverse: \Plant.grow)
        var plants: [Plant]

        init(id: UUID = UUID(), growName: String, createdAt: Date = Date()) {
            self.id = id
            self.growName = growName
            self.createdAt = createdAt
            self.plants = []
        }
    }

    @Model
    nonisolated final class Plant {
        @Attribute(.unique) var id: UUID
        var plantName: String
        var potSize: String
        var mediumType: String
        var maxRetentionCapacity: Double
        var goalRunoffPercent: Double = 15.0
        var createdAt: Date = Date()

        @Relationship(deleteRule: .cascade, inverse: \WateringLog.plant)
        var wateringLogs: [WateringLog]

        var grow: Grow?

        init(
            id: UUID = UUID(),
            plantName: String,
            potSize: String,
            mediumType: String,
            maxRetentionCapacity: Double,
            goalRunoffPercent: Double = 15.0,
            createdAt: Date = Date(),
            grow: Grow? = nil
        ) {
            self.id = id
            self.plantName = plantName
            self.potSize = potSize
            self.mediumType = mediumType
            self.maxRetentionCapacity = maxRetentionCapacity
            self.goalRunoffPercent = goalRunoffPercent
            self.createdAt = createdAt
            self.wateringLogs = []
            self.grow = grow
        }
    }

    @Model
    nonisolated final class WateringLog {
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
            self.retained = max(0, waterAdded - runoffCollected)
            self.runoffPercent = waterAdded > 0 ? min(runoffCollected / waterAdded * 100.0, 100.0) : 0
            self.intervalHours = intervalHours
            self.plant = plant
        }
    }
}
