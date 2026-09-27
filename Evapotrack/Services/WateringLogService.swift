// © 2026 Evapotrack. All rights reserved.
// WateringLogService.swift
// Evapotrack
//
// CRUD operations for WateringLog entities.
// Adding or deleting a log triggers intervalHours
// recalculation for all logs of that plant.
// A failed save rolls back, so nothing half-done stays in memory.

import Foundation
import SwiftData
import OSLog

@MainActor
final class WateringLogService {

    private let modelContext: ModelContext
    private let save: SaveHandler

    init(modelContext: ModelContext, save: @escaping SaveHandler = { try $0.save() }) {
        self.modelContext = modelContext
        self.save = save
    }

    /// Add a new watering log to a plant and recalculate intervals.
    func addLog(_ log: WateringLog, to plant: Plant) throws {
        log.plant = plant
        modelContext.insert(log)
        // SwiftData wires the inverse relationship automatically.
        // Explicitly append to ensure the in-memory array is current
        // before recalculation (SwiftData may defer the update).
        if !plant.wateringLogs.contains(where: { $0 === log }) {
            plant.wateringLogs.append(log)
        }
        recalculateIntervals(for: plant)
        do {
            try modelContext.saveOrRollback(using: save, action: "Add watering log")
        } catch {
            // The rollback restores what is on disk. Make sure the unsaved log
            // is not left in the plant's list either, or a retry would be
            // rejected as a duplicate timestamp.
            plant.wateringLogs.removeAll { $0 === log }
            throw error
        }
        Logger.services.info("Added watering log")
    }

    /// Fetch all logs for a plant, sorted newest first.
    func fetchLogs(for plant: Plant) -> [WateringLog] {
        plant.wateringLogs.sorted { $0.dateTime > $1.dateTime }
    }

    /// Delete a log and recalculate intervals for its plant.
    func deleteLog(_ log: WateringLog) throws {
        let plant = log.plant
        modelContext.delete(log)

        if let plant {
            // Eagerly remove from relationship array — SwiftData may not
            // reflect the delete in-memory until the next save/fetch cycle.
            plant.wateringLogs.removeAll { $0 === log }
            recalculateIntervals(for: plant)
        }

        try modelContext.saveOrRollback(using: save, action: "Delete watering log")
        Logger.services.info("Deleted watering log")
    }

    // MARK: - Private

    private func recalculateIntervals(for plant: Plant) {
        WateringCalculationService.recalculateIntervalHours(for: plant.wateringLogs)
    }
}
