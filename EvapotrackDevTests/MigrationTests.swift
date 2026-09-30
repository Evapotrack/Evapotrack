// © 2026 Evapotrack. All rights reserved.
// MigrationTests.swift
// EvapotrackDevTests
//
// Opens stores written with the version 1.x model (SchemaV1) using the
// current schema and migration plan, and checks that every grow, plant and
// watering log survives with identical values and no photo.
//
// Most stores are created by the tests from the frozen SchemaV1 classes. The
// stronger check, a store file written by the real App Store build, runs
// once that file is added to Fixtures/ (see Fixtures/README.md); until then
// it is skipped, not passed.

import XCTest
import SwiftData
@testable import EvapotrackDev

@MainActor
final class MigrationTests: XCTestCase {

    // MARK: - Fixture

    private struct Fixture {
        let growID = UUID()
        let plantID = UUID()
        let logIDs = [UUID(), UUID(), UUID()]
        let created = Date(timeIntervalSince1970: 1_740_000_000)

        func logDate(_ index: Int) -> Date { created.addingTimeInterval(Double(index) * 172_800) }
        func water(_ index: Int) -> Double { 1.2 + Double(index) * 0.1 }
    }

    private func temporaryStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "EvapotrackMigration-\(UUID().uuidString).store")
    }

    private func removeStore(at url: URL) {
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
        }
    }

    private func currentConfiguration(at url: URL) -> ModelConfiguration {
        ModelConfiguration(schema: PersistenceController.schema, url: url)
    }

    private func writeV1Data(_ fixture: Fixture, into context: ModelContext) throws {
        let grow = SchemaV1.Grow(id: fixture.growID, growName: "Tent A", createdAt: fixture.created)
        context.insert(grow)
        let plant = SchemaV1.Plant(
            id: fixture.plantID,
            plantName: "Plant 1",
            potSize: "Fabric 3 gal",
            mediumType: "coco",
            maxRetentionCapacity: 4.5678,
            goalRunoffPercent: 20,
            createdAt: fixture.created,
            grow: grow
        )
        context.insert(plant)
        for (index, id) in fixture.logIDs.enumerated() {
            let log = SchemaV1.WateringLog(
                id: id,
                waterAdded: fixture.water(index),
                runoffCollected: 0.18,
                dateTime: fixture.logDate(index),
                temperatureCelsius: index == 0 ? 24.5 : nil,
                humidityPercent: index == 1 ? 55 : nil,
                intervalHours: index == 0 ? nil : 48,
                plant: plant
            )
            context.insert(log)
        }
        try context.save()
    }

    private func assertMigrated(_ fixture: Fixture, in container: ModelContainer) throws {
        let context = ModelContext(container)

        let grows = try context.fetch(FetchDescriptor<Grow>())
        XCTAssertEqual(grows.count, 1)
        let grow = try XCTUnwrap(grows.first)
        XCTAssertEqual(grow.id, fixture.growID)
        XCTAssertEqual(grow.growName, "Tent A")
        XCTAssertEqual(grow.createdAt, fixture.created)
        XCTAssertEqual(grow.plants.count, 1)

        let plants = try context.fetch(FetchDescriptor<Plant>())
        XCTAssertEqual(plants.count, 1)
        let plant = try XCTUnwrap(plants.first)
        XCTAssertEqual(plant.id, fixture.plantID)
        XCTAssertEqual(plant.plantName, "Plant 1")
        XCTAssertEqual(plant.potSize, "Fabric 3 gal")
        XCTAssertEqual(plant.mediumType, "coco")
        XCTAssertEqual(plant.maxRetentionCapacity, 4.5678)
        XCTAssertEqual(plant.goalRunoffPercent, 20)
        XCTAssertEqual(plant.createdAt, fixture.created)
        XCTAssertEqual(plant.grow?.id, fixture.growID)
        XCTAssertEqual(plant.wateringLogs.count, 3)

        let logs = try context.fetch(FetchDescriptor<WateringLog>(sortBy: [SortDescriptor(\.dateTime)]))
        XCTAssertEqual(logs.map(\.id), fixture.logIDs)
        for (index, log) in logs.enumerated() {
            XCTAssertEqual(log.waterAdded, fixture.water(index))
            XCTAssertEqual(log.runoffCollected, 0.18)
            XCTAssertEqual(log.retained, fixture.water(index) - 0.18, accuracy: 1e-12)
            XCTAssertEqual(log.dateTime, fixture.logDate(index))
            XCTAssertEqual(log.temperatureCelsius, index == 0 ? 24.5 : nil)
            XCTAssertEqual(log.humidityPercent, index == 1 ? 55 : nil)
            XCTAssertEqual(log.intervalHours, index == 0 ? nil : 48)
            XCTAssertEqual(log.plant?.id, fixture.plantID)
            XCTAssertNil(log.photoFileID)
        }
    }

    // MARK: - Store written by the App Store build

    /// Opens a store captured from the App Store build (1.0) after tapping
    /// "Try Example Data", as described in Fixtures/README.md. That build made
    /// one grow with two plants (capacities 1.6 L and 2.1 L) and six logs each.
    func test_storeWrittenByTheAppStoreBuild_opensWithEveryRecord() throws {
        let bundle = Bundle(for: MigrationTests.self)
        guard let captured = bundle.url(forResource: "shipped-1.0", withExtension: "store") else {
            throw XCTSkip("No store from the App Store build in Fixtures/ yet. See Fixtures/README.md.")
        }
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "EvapotrackShipped-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "default.store")
        try FileManager.default.copyItem(at: captured, to: url)
        for suffix in ["-wal", "-shm"] {
            if let extra = bundle.url(forResource: "shipped-1.0", withExtension: "store\(suffix)") {
                try FileManager.default.copyItem(at: extra, to: URL(fileURLWithPath: url.path + suffix))
            }
        }

        // Open twice: the migration, then a normal relaunch of the migrated store.
        for _ in 0..<2 {
            let container = try PersistenceController.makeContainer(configuration: currentConfiguration(at: url))
            let context = ModelContext(container)

            XCTAssertEqual(try context.fetchCount(FetchDescriptor<Grow>()), 1)
            let plants = try context.fetch(FetchDescriptor<Plant>(sortBy: [SortDescriptor(\.maxRetentionCapacity)]))
            XCTAssertEqual(plants.map(\.maxRetentionCapacity), [1.6, 2.1])
            XCTAssertEqual(plants.map(\.wateringLogs.count), [6, 6])
            XCTAssertTrue(plants.allSatisfy { $0.grow != nil })

            let logs = try context.fetch(FetchDescriptor<WateringLog>())
            XCTAssertEqual(logs.count, 12)
            for log in logs {
                XCTAssertNil(log.photoFileID)
                XCTAssertNotNil(log.plant)
                XCTAssertEqual(log.retained, max(0, log.waterAdded - log.runoffCollected), accuracy: 1e-9)
            }
        }
    }

    // MARK: - V1 to V2

    func test_unversionedV1Store_opensWithCurrentSchema_keepingEveryRecord() throws {
        let url = temporaryStoreURL()
        defer { removeStore(at: url) }
        let fixture = Fixture()

        do {
            // Written the way 1.x releases wrote their store: no versioned schema.
            let container = try ModelContainer(
                for: SchemaV1.Grow.self, SchemaV1.Plant.self, SchemaV1.WateringLog.self,
                configurations: ModelConfiguration(url: url)
            )
            try writeV1Data(fixture, into: ModelContext(container))
        }

        let migrated = try PersistenceController.makeContainer(configuration: currentConfiguration(at: url))
        try assertMigrated(fixture, in: migrated)
    }

    func test_versionedV1Store_migratesToV2_keepingEveryRecord() throws {
        let url = temporaryStoreURL()
        defer { removeStore(at: url) }
        let fixture = Fixture()

        do {
            let schemaV1 = Schema(versionedSchema: SchemaV1.self)
            let container = try ModelContainer(for: schemaV1, configurations: ModelConfiguration(schema: schemaV1, url: url))
            try writeV1Data(fixture, into: ModelContext(container))
        }

        let migrated = try PersistenceController.makeContainer(configuration: currentConfiguration(at: url))
        try assertMigrated(fixture, in: migrated)
    }

    func test_migratedStore_keepsPhotoIdentifiersAcrossRelaunch() throws {
        let url = temporaryStoreURL()
        defer { removeStore(at: url) }
        let fixture = Fixture()
        let photoID = UUID()

        do {
            let container = try ModelContainer(
                for: SchemaV1.Grow.self, SchemaV1.Plant.self, SchemaV1.WateringLog.self,
                configurations: ModelConfiguration(url: url)
            )
            try writeV1Data(fixture, into: ModelContext(container))
        }
        do {
            let container = try PersistenceController.makeContainer(configuration: currentConfiguration(at: url))
            let context = ModelContext(container)
            let logs = try context.fetch(FetchDescriptor<WateringLog>(sortBy: [SortDescriptor(\.dateTime)]))
            try XCTUnwrap(logs.first).photoFileID = photoID
            try context.save()
        }

        let reopened = try PersistenceController.makeContainer(configuration: currentConfiguration(at: url))
        let logs = try ModelContext(reopened).fetch(FetchDescriptor<WateringLog>(sortBy: [SortDescriptor(\.dateTime)]))
        XCTAssertEqual(logs.first?.photoFileID, photoID)
        XCTAssertEqual(logs.dropFirst().compactMap(\.photoFileID), [])
    }

    func test_storeFromAnUnknownOlderModel_stillOpensWithDataIntact() throws {
        // The fallback path: a model that matches no version in the plan.
        let url = temporaryStoreURL()
        defer { removeStore(at: url) }
        let growID = UUID(), plantID = UUID(), logID = UUID()
        let date = Date(timeIntervalSince1970: 1_740_000_000)

        do {
            let container = try ModelContainer(
                for: PreV1Schema.Grow.self, PreV1Schema.Plant.self, PreV1Schema.WateringLog.self,
                configurations: ModelConfiguration(url: url)
            )
            let context = ModelContext(container)
            let grow = PreV1Schema.Grow(id: growID, growName: "Old Tent", createdAt: date)
            context.insert(grow)
            let plant = PreV1Schema.Plant(id: plantID, plantName: "Old Plant", potSize: "1 gal", mediumType: "soil", maxRetentionCapacity: 1.5, grow: grow)
            context.insert(plant)
            context.insert(PreV1Schema.WateringLog(id: logID, waterAdded: 1.0, runoffCollected: 0.1, dateTime: date, plant: plant))
            try context.save()
        }

        let container = try PersistenceController.makeContainer(configuration: currentConfiguration(at: url))
        let context = ModelContext(container)
        let plant = try XCTUnwrap(try context.fetch(FetchDescriptor<Plant>()).first)
        XCTAssertEqual(plant.id, plantID)
        XCTAssertEqual(plant.maxRetentionCapacity, 1.5)
        XCTAssertEqual(plant.goalRunoffPercent, AppConstants.targetRunoffPercent)
        let log = try XCTUnwrap(try context.fetch(FetchDescriptor<WateringLog>()).first)
        XCTAssertEqual(log.id, logID)
        XCTAssertEqual(log.waterAdded, 1.0)
        XCTAssertNil(log.photoFileID)
    }

    // MARK: - Schema drift guard

    func test_schemaV2_addsOnlyPhotoFileIDToV1() {
        let v1 = Schema(versionedSchema: SchemaV1.self)
        let v2 = Schema(versionedSchema: SchemaV2.self)

        func propertyNames(_ schema: Schema, _ entityName: String) -> Set<String> {
            guard let entity = schema.entities.first(where: { $0.name == entityName }) else { return [] }
            return Set(entity.attributes.map(\.name)).union(entity.relationships.map(\.name))
        }

        for entity in ["Grow", "Plant"] {
            XCTAssertFalse(propertyNames(v1, entity).isEmpty, entity)
            XCTAssertEqual(propertyNames(v1, entity), propertyNames(v2, entity), entity)
        }
        let v1Log = propertyNames(v1, "WateringLog")
        let v2Log = propertyNames(v2, "WateringLog")
        XCTAssertFalse(v1Log.isEmpty)
        XCTAssertEqual(v2Log.subtracting(v1Log), ["photoFileID"])
        XCTAssertEqual(v1Log.subtracting(v2Log), [])
    }
}
