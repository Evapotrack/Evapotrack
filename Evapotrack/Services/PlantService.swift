// © 2026 Evapotrack. All rights reserved.
// PlantService.swift
// Evapotrack
//
// CRUD operations for Plant entities using SwiftData.
// A failed save rolls back, so nothing half-done stays in memory.

import Foundation
import SwiftData
import OSLog

@MainActor
final class PlantService {

    private let modelContext: ModelContext
    private let save: SaveHandler

    init(modelContext: ModelContext, save: @escaping SaveHandler = { try $0.save() }) {
        self.modelContext = modelContext
        self.save = save
    }

    func addPlant(_ plant: Plant) throws {
        let totalCount = (try? modelContext.fetchCount(FetchDescriptor<Plant>())) ?? 0
        guard totalCount < AppConstants.maxTotalPlants else {
            Logger.services.warning("Total plant limit reached (\(AppConstants.maxTotalPlants))")
            throw ServiceError.limitExceeded
        }
        if let grow = plant.grow {
            let perGrowCount = grow.plants.count
            guard perGrowCount < AppConstants.maxPlantsPerGrow else {
                Logger.services.warning("Per-grow plant limit reached (\(AppConstants.maxPlantsPerGrow))")
                throw ServiceError.limitExceeded
            }
        }
        modelContext.insert(plant)
        try modelContext.saveOrRollback(using: save, action: "Add plant")
        Logger.services.info("Added plant")
    }

    func fetchAll() -> [Plant] {
        let descriptor = FetchDescriptor<Plant>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            Logger.services.error("Failed to fetch plants: \(error.localizedDescription)")
            return []
        }
    }

    /// Updates a plant's details. Watering logs are not touched: retained
    /// volumes stay as measured, and Capacity % and Next recalculate from the
    /// new values the next time they are shown.
    func updatePlant(
        _ plant: Plant,
        name: String,
        potSize: String,
        mediumType: String,
        maxRetentionCapacity: Double,
        goalRunoffPercent: Double
    ) throws {
        plant.plantName = name
        plant.potSize = potSize
        plant.mediumType = mediumType
        plant.maxRetentionCapacity = maxRetentionCapacity
        plant.goalRunoffPercent = goalRunoffPercent
        try modelContext.saveOrRollback(using: save, action: "Edit plant")
        Logger.services.info("Edited plant")
    }

    /// Deletes the plant and, by cascade, its watering logs.
    func deletePlant(_ plant: Plant) throws {
        modelContext.delete(plant)
        try modelContext.saveOrRollback(using: save, action: "Delete plant")
        Logger.services.info("Deleted plant")
    }
}
