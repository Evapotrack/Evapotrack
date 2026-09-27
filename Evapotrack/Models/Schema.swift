// © 2026 Evapotrack. All rights reserved.
// Schema.swift
// Evapotrack
//
// Versioned SwiftData schema and migration plan.
//
//   SchemaV1 — the model shipped through version 1.x (frozen, SchemaV1.swift)
//   SchemaV2 — adds WateringLog.photoFileID (optional, defaults to nil)
//
// The rest of the app uses the typealiases below, which always point at the
// current schema. To change the model: freeze the current classes into a new
// SchemaVn copy, edit the current classes, bump the version, and add a
// migration stage.

import Foundation
import SwiftData

typealias Grow = SchemaV2.Grow
typealias Plant = SchemaV2.Plant
typealias WateringLog = SchemaV2.WateringLog

nonisolated enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [Grow.self, Plant.self, WateringLog.self]
    }
}

nonisolated enum EvapotrackMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        // Adding an optional property is a lightweight migration: existing
        // grows, plants and logs are kept as they are and photoFileID is nil.
        [.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)]
    }
}
