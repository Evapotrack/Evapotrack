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

    func addPlant(_ plant: Plant) {
        modelContext.insert(plant)
        save()
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

    func deletePlant(_ plant: Plant) {
        let name = plant.plantName
        modelContext.delete(plant)
        save()
        Logger.services.info("Deleted plant: \(name)")
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            Logger.data.error("Failed to save context: \(error.localizedDescription)")
        }
    }
}
