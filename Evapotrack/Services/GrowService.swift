// GrowService.swift
// Evapotrack
//
// CRUD operations for Grow entities using SwiftData.

import Foundation
import SwiftData
import OSLog

@MainActor
final class GrowService {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func addGrow(_ grow: Grow) throws {
        modelContext.insert(grow)
        try modelContext.save()
        Logger.services.info("Added grow: \(grow.growName)")
    }

    func fetchAll() -> [Grow] {
        let descriptor = FetchDescriptor<Grow>(
            sortBy: [SortDescriptor(\.growName)]
        )
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            Logger.services.error("Failed to fetch grows: \(error.localizedDescription)")
            return []
        }
    }

    func deleteGrow(_ grow: Grow) throws {
        let name = grow.growName
        modelContext.delete(grow)
        try modelContext.save()
        Logger.services.info("Deleted grow: \(name)")
    }
}
