// © 2026 Evapotrack. All rights reserved.
// PersistenceController.swift
// Evapotrack
//
// Opens the SwiftData store with the versioned schema and migration plan.
// The app shows an error screen instead of crashing or starting with an
// empty store if the store cannot be opened.

import Foundation
import OSLog
import SwiftData

nonisolated enum PersistenceController {

    /// The current schema, as used by the app and tests.
    static var schema: Schema { Schema(versionedSchema: SchemaV2.self) }

    /// Opens the store at the default location (Application Support/default.store,
    /// the same file earlier releases used), or at `configuration` if given.
    static func makeContainer(configuration: ModelConfiguration? = nil) throws -> ModelContainer {
        let schema = Self.schema
        let config = configuration ?? ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, migrationPlan: EvapotrackMigrationPlan.self, configurations: config)
        } catch {
            // A store written by a build whose model matches no known schema
            // version cannot use the staged plan. Fall back to automatic
            // lightweight migration, which is how every earlier release opened
            // its store. A failed staged migration leaves the store untouched.
            Logger.services.error("Versioned store open failed, retrying with automatic migration: \(error.localizedDescription, privacy: .public)")
            return try ModelContainer(for: schema, configurations: config)
        }
    }

    /// An empty in-memory store for tests and previews.
    static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Self.schema
        return try ModelContainer(
            for: schema,
            migrationPlan: EvapotrackMigrationPlan.self,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
    }
}
