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
        modelContext.insert(plant)
        try modelContext.save()
        Logger.services.info("Added plant: \(plant.plantName)")
    }

    func fetchAll() -> [Plant] {
        let descriptor = FetchDescriptor<Plant>(
            sortBy: [SortDescriptor(\.plantName)]
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
