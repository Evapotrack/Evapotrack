// © 2026 Evapotrack. All rights reserved.
// GrowService.swift
// Evapotrack
//
// CRUD operations for Grow entities using SwiftData.
// A failed save rolls back, so nothing half-done stays in memory.

import Foundation
import SwiftData
import OSLog

@MainActor
final class GrowService {

    private let modelContext: ModelContext
    private let save: SaveHandler

    init(modelContext: ModelContext, save: @escaping SaveHandler = { try $0.save() }) {
        self.modelContext = modelContext
        self.save = save
    }

    func addGrow(_ grow: Grow) throws {
        let count = (try? modelContext.fetchCount(FetchDescriptor<Grow>())) ?? 0
        guard count < AppConstants.maxGrowCount else {
            Logger.services.warning("Grow limit reached (\(AppConstants.maxGrowCount))")
            throw ServiceError.limitExceeded
        }
        modelContext.insert(grow)
        try modelContext.saveOrRollback(using: save, action: "Add grow")
        Logger.services.info("Added grow")
    }

    func fetchAll() -> [Grow] {
        let descriptor = FetchDescriptor<Grow>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            Logger.services.error("Failed to fetch grows: \(error.localizedDescription)")
            return []
        }
    }

    /// Deletes the grow and, by cascade, its plants and their logs.
    func deleteGrow(_ grow: Grow) throws {
        modelContext.delete(grow)
        try modelContext.saveOrRollback(using: save, action: "Delete grow")
        Logger.services.info("Deleted grow")
    }
}
