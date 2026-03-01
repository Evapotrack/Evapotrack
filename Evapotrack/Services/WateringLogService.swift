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
    func addLog(_ log: WateringLog, to plant: Plant) {
        log.plant = plant
        plant.wateringLogs.append(log)
        modelContext.insert(log)
        recalculateIntervals(for: plant)
        save()
        Logger.services.info("Added watering log to \(plant.plantName)")
    }

    /// Fetch all logs for a plant, sorted newest first.
    func fetchLogs(for plant: Plant) -> [WateringLog] {
        plant.wateringLogs.sorted { $0.dateTime > $1.dateTime }
    }

    /// Delete a log and recalculate intervals for its plant.
    func deleteLog(_ log: WateringLog) {
        let plant = log.plant
        modelContext.delete(log)

        if let plant = plant {
            // Remove from array before recalculating
            plant.wateringLogs.removeAll { $0.id == log.id }
            recalculateIntervals(for: plant)
        }

        save()
        Logger.services.info("Deleted watering log")
    }

    /// Most recent log for a plant by dateTime.
    func mostRecentLog(for plant: Plant) -> WateringLog? {
        plant.wateringLogs.max(by: { $0.dateTime < $1.dateTime })
    }

    // MARK: - Private

    private func recalculateIntervals(for plant: Plant) {
        var logs = plant.wateringLogs
        WateringCalculationService.recalculateIntervalHours(for: &logs)
    }

    func save() {
        do {
            try modelContext.save()
        } catch {
            Logger.data.error("Failed to save context: \(error.localizedDescription)")
        }
    }
}
