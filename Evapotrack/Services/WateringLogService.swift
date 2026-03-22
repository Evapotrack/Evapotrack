// © 2026 Evapotrack. All rights reserved.
// WateringLogService.swift
// Evapotrack
//
// CRUD operations for WateringLog entities.
// Adding or deleting a log triggers intervalHours
// recalculation for all logs of that plant.

import Foundation
import SwiftData
import OSLog

@MainActor
final class WateringLogService {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Add a new watering log to a plant and recalculate intervals.
    func addLog(_ log: WateringLog, to plant: Plant) throws {
        log.plant = plant
        modelContext.insert(log)
        // SwiftData wires the inverse relationship automatically.
        // Explicitly append to ensure the in-memory array is current
        // before recalculation (SwiftData may defer the update).
        if !plant.wateringLogs.contains(where: { $0.id == log.id }) {
            plant.wateringLogs.append(log)
        }
        recalculateIntervals(for: plant)
        try modelContext.save()
        Logger.services.info("Added watering log to \(plant.plantName)")
    }

    /// Fetch all logs for a plant, sorted newest first.
    func fetchLogs(for plant: Plant) -> [WateringLog] {
        plant.wateringLogs.sorted { $0.dateTime > $1.dateTime }
    }

    /// Delete a log and recalculate intervals for its plant.
    func deleteLog(_ log: WateringLog) throws {
        let plant = log.plant
        modelContext.delete(log)

        if let plant = plant {
            // Eagerly remove from relationship array — SwiftData may not
            // reflect the delete in-memory until the next save/fetch cycle.
            plant.wateringLogs.removeAll { $0.id == log.id }
            recalculateIntervals(for: plant)
        }

        try modelContext.save()
        Logger.services.info("Deleted watering log")
    }

    // MARK: - Private

    private func recalculateIntervals(for plant: Plant) {
        WateringCalculationService.recalculateIntervalHours(for: plant.wateringLogs)
    }
}
