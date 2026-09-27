// © 2026 Evapotrack. All rights reserved.
// PersistenceTests.swift
// EvapotrackDevTests
//
// Save-failure behavior: when a save fails, every service rolls back so
// nothing half-done stays in memory, no failed insert is committed later by
// autosave, and a retry is not blocked by leftovers. Also covers the
// example-data loader.

import XCTest
import SwiftData
@testable import EvapotrackDev

@MainActor
final class PersistenceTests: XCTestCase {

    private struct SaveFailed: Error {}
    private let failingSave: SaveHandler = { _ in throw SaveFailed() }

    private func makeContext() throws -> ModelContext {
        ModelContext(try PersistenceController.makeInMemoryContainer())
    }

    private func count<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws -> Int {
        try context.fetchCount(FetchDescriptor<T>())
    }

    /// A saved grow with one plant and `logCount` logs a day apart.
    private func seed(_ context: ModelContext, logCount: Int = 2) throws -> (Grow, Plant) {
        let grow = Grow(growName: "Tent")
        context.insert(grow)
        let plant = Plant(plantName: "P1", potSize: "3 gal", mediumType: "coco", maxRetentionCapacity: 4.5, grow: grow)
        context.insert(plant)
        let service = WateringLogService(modelContext: context)
        for index in 0..<logCount {
            let log = WateringLog(
                waterAdded: 1.2,
                runoffCollected: 0.18,
                dateTime: WateringHistory.start.addingTimeInterval(Double(index) * 86_400)
            )
            try service.addLog(log, to: plant)
        }
        return (grow, plant)
    }

    // MARK: - Watering logs

    func test_addLog_failedSave_leavesNothingBehind_andRetrySucceeds() throws {
        let context = try makeContext()
        let (_, plant) = try seed(context, logCount: 1)
        let date = WateringHistory.start.addingTimeInterval(2 * 86_400)

        let failing = WateringLogService(modelContext: context, save: failingSave)
        XCTAssertThrowsError(try failing.addLog(WateringLog(waterAdded: 1.0, runoffCollected: 0.1, dateTime: date), to: plant))

        XCTAssertEqual(try count(WateringLog.self, in: context), 1)
        XCTAssertEqual(plant.wateringLogs.count, 1)

        // The same watering can be logged again; no duplicate is left over.
        try WateringLogService(modelContext: context).addLog(
            WateringLog(waterAdded: 1.0, runoffCollected: 0.1, dateTime: date), to: plant
        )
        XCTAssertEqual(try count(WateringLog.self, in: context), 2)
        XCTAssertEqual(plant.wateringLogs.count, 2)
    }

    func test_deleteLog_failedSave_keepsTheLog() throws {
        let context = try makeContext()
        let (_, plant) = try seed(context, logCount: 2)
        let log = try XCTUnwrap(plant.wateringLogs.first)

        XCTAssertThrowsError(try WateringLogService(modelContext: context, save: failingSave).deleteLog(log))

        XCTAssertEqual(try count(WateringLog.self, in: context), 2)
        XCTAssertEqual(plant.wateringLogs.count, 2)
        XCTAssertFalse(context.hasChanges)
    }

    func test_deleteLog_recalculatesRemainingIntervals() throws {
        let context = try makeContext()
        let (_, plant) = try seed(context, logCount: 3)
        let middle = try XCTUnwrap(plant.wateringLogs.sorted { $0.dateTime < $1.dateTime }[safe: 1])

        try WateringLogService(modelContext: context).deleteLog(middle)

        let remaining = plant.wateringLogs.sorted { $0.dateTime < $1.dateTime }
        XCTAssertEqual(remaining.count, 2)
        XCTAssertNil(remaining[0].intervalHours)
        XCTAssertEqual(try XCTUnwrap(remaining[1].intervalHours), 48, accuracy: 1e-9)
    }

    // MARK: - Plants and grows

    func test_addPlant_failedSave_insertsNothing() throws {
        let context = try makeContext()
        let (grow, _) = try seed(context, logCount: 0)
        try context.save()
        let plant = Plant(plantName: "P2", potSize: "1 gal", mediumType: "soil", maxRetentionCapacity: 1.5, grow: grow)

        XCTAssertThrowsError(try PlantService(modelContext: context, save: failingSave).addPlant(plant))

        XCTAssertEqual(try count(Plant.self, in: context), 1)
        XCTAssertFalse(context.hasChanges)
    }

    func test_deletePlant_failedSave_keepsPlantAndLogs() throws {
        let context = try makeContext()
        let (_, plant) = try seed(context, logCount: 2)

        XCTAssertThrowsError(try PlantService(modelContext: context, save: failingSave).deletePlant(plant))

        XCTAssertEqual(try count(Plant.self, in: context), 1)
        XCTAssertEqual(try count(WateringLog.self, in: context), 2)
    }

    func test_addGrow_failedSave_insertsNothing() throws {
        let context = try makeContext()
        XCTAssertThrowsError(try GrowService(modelContext: context, save: failingSave).addGrow(Grow(growName: "New")))
        XCTAssertEqual(try count(Grow.self, in: context), 0)
        XCTAssertFalse(context.hasChanges)
    }

    func test_deleteGrow_failedSave_keepsEverything() throws {
        let context = try makeContext()
        let (grow, _) = try seed(context, logCount: 2)

        XCTAssertThrowsError(try GrowService(modelContext: context, save: failingSave).deleteGrow(grow))

        XCTAssertEqual(try count(Grow.self, in: context), 1)
        XCTAssertEqual(try count(Plant.self, in: context), 1)
        XCTAssertEqual(try count(WateringLog.self, in: context), 2)
    }

    // MARK: - Example data

    func test_exampleData_createsTwoPlantsWithSixLogsEach() throws {
        let context = try makeContext()
        try ExampleDataService(modelContext: context).loadExampleGrow()

        XCTAssertEqual(try count(Grow.self, in: context), 1)
        let plants = try context.fetch(FetchDescriptor<Plant>())
        XCTAssertEqual(plants.count, 2)
        for plant in plants {
            let logs = plant.wateringLogs.sorted { $0.dateTime < $1.dateTime }
            XCTAssertEqual(logs.count, 6)
            XCTAssertNil(logs.first?.intervalHours)
            XCTAssertTrue(logs.dropFirst().allSatisfy { $0.intervalHours != nil })
        }
    }

    func test_exampleData_failedSave_leavesTheStoreEmpty() throws {
        let context = try makeContext()
        XCTAssertThrowsError(try ExampleDataService(modelContext: context, save: failingSave).loadExampleGrow())
        XCTAssertEqual(try count(Grow.self, in: context), 0)
        XCTAssertEqual(try count(Plant.self, in: context), 0)
        XCTAssertEqual(try count(WateringLog.self, in: context), 0)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
