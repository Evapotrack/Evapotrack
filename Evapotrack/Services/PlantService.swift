// © 2026 Evapotrack. All rights reserved.
// PlantService.swift
// Evapotrack
//
// CRUD operations for Plant entities using SwiftData.

import Foundation
import SwiftData
import OSLog

@MainActor
final class PlantService {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
        try modelContext.save()
        Logger.services.info("Added plant: \(plant.plantName)")
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

    func deletePlant(_ plant: Plant) throws {
        let name = plant.plantName
        modelContext.delete(plant)
        try modelContext.save()
        Logger.services.info("Deleted plant: \(name)")
    }
}
