// Grow.swift
// Evapotrack
//
// SwiftData model representing a grow group that contains plants.
// Immutable after creation — grows may be created or deleted
// but never edited. Deleting a grow cascade-deletes all
// associated Plants (and their WateringLogs).

import Foundation
import SwiftData

@Model
final class Grow {

    // MARK: - Stored Fields

    /// Unique identifier.
    @Attribute(.unique) var id: UUID

    /// User-given name for the grow (required).
    var growName: String

    /// Date the grow was created.
    var createdAt: Date

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade, inverse: \Plant.grow)
    var plants: [Plant]

    // MARK: - Init

    init(
        id: UUID = UUID(),
        growName: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.growName = growName
        self.createdAt = createdAt
        self.plants = []
    }
}
