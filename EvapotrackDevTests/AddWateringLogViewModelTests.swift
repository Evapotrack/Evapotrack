// © 2026 Evapotrack. All rights reserved.
// AddWateringLogViewModelTests.swift
// EvapotrackDevTests
//
// Logging a watering: comma decimals, messages in the user's units,
// duplicate timestamps, and the over-capacity confirmation that replaced
// the old hard rejection.

import XCTest
import SwiftData
@testable import EvapotrackDev

@MainActor
final class AddWateringLogViewModelTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_760_000_000)

    private func makeVM(
        capacity: Double = 1.0,
        waterUnit: WaterUnit = .liters
    ) throws -> (AddWateringLogViewModel, Plant, ModelContext) {
        let context = ModelContext(try PersistenceController.makeInMemoryContainer())
        let grow = Grow(growName: "Tent")
        context.insert(grow)
        let plant = Plant(plantName: "P1", potSize: "1 gal", mediumType: "soil", maxRetentionCapacity: capacity, grow: grow)
        context.insert(plant)
        try context.save()
        let vm = AddWateringLogViewModel(plant: plant, dateProvider: MockDateProvider(fixedDate: now))
        vm.configure(modelContext: context, waterUnit: waterUnit, temperatureUnit: .celsius)
        vm.dateTime = now.addingTimeInterval(-3600)
        return (vm, plant, context)
    }

    func test_commaDecimals_areAccepted() throws {
        let (vm, plant, _) = try makeVM()
        vm.waterAddedText = "1,1"
        vm.runoffCollectedText = "0,2"
        XCTAssertTrue(vm.save())
        let log = try XCTUnwrap(plant.wateringLogs.first)
        XCTAssertEqual(log.waterAdded, 1.1, accuracy: 1e-12)
        XCTAssertEqual(log.runoffCollected, 0.2, accuracy: 1e-12)
    }

    func test_rangeMessage_usesTheUsersWaterUnit() throws {
        let (vm, _, _) = try makeVM(waterUnit: .milliliters)
        vm.waterAddedText = "0"
        vm.runoffCollectedText = "0"
        XCTAssertFalse(vm.save())
        XCTAssertEqual(vm.validationError, "Water added must be between 1 mL and 100000 mL.")
    }

    func test_overCapacity_asksForConfirmation_thenSavesWhenConfirmed() throws {
        // Capacity 1.0 L; this watering retained 1.8 L.
        let (vm, plant, _) = try makeVM(capacity: 1.0)
        vm.waterAddedText = "2"
        vm.runoffCollectedText = "0.2"

        XCTAssertFalse(vm.save())
        XCTAssertTrue(vm.isShowingCapacityConfirmation)
        XCTAssertNil(vm.validationError)
        XCTAssertTrue(plant.wateringLogs.isEmpty)

        XCTAssertTrue(vm.save(confirmedOverCapacity: true))
        let log = try XCTUnwrap(plant.wateringLogs.first)
        XCTAssertEqual(log.retained, 1.8, accuracy: 1e-12)
    }

    func test_withinTolerance_savesWithoutConfirmation() throws {
        // 1.04 L retained against a 1.0 L capacity is within the 5% tolerance.
        let (vm, _, _) = try makeVM(capacity: 1.0)
        vm.waterAddedText = "1.2"
        vm.runoffCollectedText = "0.16"
        XCTAssertTrue(vm.save())
        XCTAssertFalse(vm.isShowingCapacityConfirmation)
    }

    func test_hardErrorsAreReportedBeforeTheCapacityQuestion() throws {
        let (vm, plant, _) = try makeVM(capacity: 1.0)
        let service = WateringLogService(modelContext: try XCTUnwrap(plant.modelContext))
        try service.addLog(WateringLog(waterAdded: 1.0, runoffCollected: 0.1, dateTime: vm.dateTime), to: plant)

        vm.waterAddedText = "2"
        vm.runoffCollectedText = "0.2"
        XCTAssertFalse(vm.save())
        XCTAssertEqual(vm.validationError, Strings.duplicateLogTimestamp)
        XCTAssertFalse(vm.isShowingCapacityConfirmation)
    }
}
