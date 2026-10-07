// © 2026 Evapotrack. All rights reserved.
// WateringLogService.swift
// Evapotrack
//
// CRUD operations for WateringLog entities.
// Adding or deleting a log triggers intervalHours
// recalculation for all logs of that plant.
// A failed save rolls back, so nothing half-done stays in memory.
// Photo files follow the database: a photo is copied into place before the
// log is saved (and removed again if the save fails), and deleted only
// after the log's deletion is saved.

import Foundation
import SwiftData
import OSLog

@MainActor
final class WateringLogService {

    private let modelContext: ModelContext
    private let save: SaveHandler
    private let photoStore: PhotoStore

    init(
        modelContext: ModelContext,
        photoStore: PhotoStore = .shared,
        save: @escaping SaveHandler = { try $0.save() }
    ) {
        self.modelContext = modelContext
        self.photoStore = photoStore
        self.save = save
    }

    /// Add a new watering log (with an optional prepared photo) to a plant and
    /// recalculate intervals.
    func addLog(_ log: WateringLog, to plant: Plant, photo: PreparedPhoto? = nil) throws {
        if let photo {
            try photoStore.commit(photo)
            log.photoFileID = photo.id
        }
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
            // rejected as a duplicate timestamp. The placed photo copy goes;
            // the prepared copy stays so the grower can retry.
            plant.wateringLogs.removeAll { $0 === log }
            if let photo { photoStore.deletePhoto(id: photo.id) }
            throw error
        }
        if let photo { photoStore.discard(photo) }
        Logger.services.info("Added watering log")
    }

    /// Fetch all logs for a plant, sorted newest first.
    func fetchLogs(for plant: Plant) -> [WateringLog] {
        plant.wateringLogs.sorted { $0.dateTime > $1.dateTime }
    }

    /// Delete a log and recalculate intervals for its plant.
    func deleteLog(_ log: WateringLog) throws {
        let plant = log.plant
        let photoID = log.photoFileID
        modelContext.delete(log)

        if let plant {
            // Eagerly remove from relationship array — SwiftData may not
            // reflect the delete in-memory until the next save/fetch cycle.
            plant.wateringLogs.removeAll { $0 === log }
            recalculateIntervals(for: plant)
        }

        try modelContext.saveOrRollback(using: save, action: "Delete watering log")
        if let photoID { photoStore.deletePhoto(id: photoID) }
        Logger.services.info("Deleted watering log")
    }

    // MARK: - Private

    private func recalculateIntervals(for plant: Plant) {
        WateringCalculationService.recalculateIntervalHours(for: plant.wateringLogs)
    }
}
