// © 2026 Evapotrack. All rights reserved.
// PlantFormViewModelTests.swift
// EvapotrackDevTests
//
// Creating and editing plants: Max Retention Capacity is stored unrounded,
// edits keep untouched values exactly, and editing never alters logs.

import XCTest
import SwiftData
@testable import EvapotrackDev

@MainActor
final class PlantFormViewModelTests: XCTestCase {

    private func makeContext() throws -> ModelContext {
        ModelContext(try PersistenceController.makeInMemoryContainer())
    }

    private func makeGrow(in context: ModelContext) throws -> Grow {
        let grow = Grow(growName: "Tent")
        context.insert(grow)
        try context.save()
        return grow
    }

    private func fillRequiredFields(_ vm: PlantFormViewModel, name: String = "Plant 1") {
        vm.plantName = name
        vm.potSize = "Fabric 3 gal"
        vm.mediumType = "coco"
    }

    // MARK: - Create

    func test_calculatorResult_isStoredUnrounded() throws {
        let context = try makeContext()
        let grow = try makeGrow(in: context)
        let vm = PlantFormViewModel(mode: .create(grow))
        vm.configure(modelContext: context, waterUnit: .gallons)
        fillRequiredFields(vm)

        vm.calculatorWaterAddedText = "0.5"
        vm.calculatorRunoffText = "0.0763"
        vm.calculate()
        XCTAssertNil(vm.calculatorError)
        XCTAssertEqual(vm.maxRetentionCapacityText, "0.42")

        XCTAssertTrue(vm.save())
        let plant = try XCTUnwrap(try context.fetch(FetchDescriptor<Plant>()).first)
        // 0.4237 gal, not the 0.42 gal shown in the field.
        XCTAssertEqual(plant.maxRetentionCapacity, UnitConversionService.toLiters(0.4237, from: .gallons), accuracy: 1e-12)
    }

    func test_typedCapacity_replacesCalculatorResult() throws {
        let context = try makeContext()
        let grow = try makeGrow(in: context)
        let vm = PlantFormViewModel(mode: .create(grow))
        vm.configure(modelContext: context, waterUnit: .liters)
        fillRequiredFields(vm)

        vm.calculatorWaterAddedText = "2"
        vm.calculatorRunoffText = "0.3"
        vm.calculate()
        vm.maxRetentionCapacityText = "4,5"

        XCTAssertTrue(vm.save())
        let plant = try XCTUnwrap(try context.fetch(FetchDescriptor<Plant>()).first)
        XCTAssertEqual(plant.maxRetentionCapacity, 4.5, accuracy: 1e-12)
    }

    func test_calculator_rejectsRunoffEqualToWater() throws {
        let context = try makeContext()
        let vm = PlantFormViewModel(mode: .create(try makeGrow(in: context)))
        vm.configure(modelContext: context, waterUnit: .liters)
        vm.calculatorWaterAddedText = "1"
        vm.calculatorRunoffText = "1"
        vm.calculate()
        XCTAssertEqual(vm.calculatorError, Strings.calculatorRunoffTooLarge)
    }

    func test_goal_blankMeansDefault_andOutsideRangeIsRejected() throws {
        let context = try makeContext()
        let grow = try makeGrow(in: context)
        let vm = PlantFormViewModel(mode: .create(grow))
        vm.configure(modelContext: context, waterUnit: .liters)
        fillRequiredFields(vm)
        vm.maxRetentionCapacityText = "4.5"

        vm.goalRunoffPercentText = "60"
        XCTAssertFalse(vm.validate())
        XCTAssertEqual(vm.validationError, Strings.goalRunoffRange)

        vm.goalRunoffPercentText = ""
        XCTAssertTrue(vm.save())
        let plant = try XCTUnwrap(try context.fetch(FetchDescriptor<Plant>()).first)
        XCTAssertEqual(plant.goalRunoffPercent, AppConstants.targetRunoffPercent)
    }

    // MARK: - Edit

    private func makePlantWithLogs(in context: ModelContext, capacity: Double = 1.6042, goal: Double = 15) throws -> Plant {
        let grow = try makeGrow(in: context)
        let plant = Plant(plantName: "Plant 1", potSize: "1 gal", mediumType: "soil", maxRetentionCapacity: capacity, goalRunoffPercent: goal, grow: grow)
        context.insert(plant)
        try context.save()
        let service = WateringLogService(modelContext: context)
        try service.addLog(WateringLog(waterAdded: 1.2, runoffCollected: 0.2, dateTime: WateringHistory.start), to: plant)
        return plant
    }

    func test_edit_keepsUntouchedCapacityExactly() throws {
        let context = try makeContext()
        let plant = try makePlantWithLogs(in: context)
        let vm = PlantFormViewModel(mode: .edit(plant))
        vm.configure(modelContext: context, waterUnit: .liters)
        XCTAssertEqual(vm.maxRetentionCapacityText, "1.60")

        vm.plantName = "Renamed"
        XCTAssertTrue(vm.save())
        XCTAssertEqual(plant.plantName, "Renamed")
        XCTAssertEqual(plant.maxRetentionCapacity, 1.6042)
    }

    func test_edit_newCapacity_changesCapacityPercentButNotLogs() throws {
        let context = try makeContext()
        let plant = try makePlantWithLogs(in: context)
        let log = try XCTUnwrap(plant.wateringLogs.first)
        let vm = PlantFormViewModel(mode: .edit(plant))
        vm.configure(modelContext: context, waterUnit: .liters)

        vm.maxRetentionCapacityText = "2"
        XCTAssertTrue(vm.save())

        XCTAssertEqual(plant.maxRetentionCapacity, 2.0, accuracy: 1e-12)
        XCTAssertEqual(log.waterAdded, 1.2)
        XCTAssertEqual(log.runoffCollected, 0.2)
        XCTAssertEqual(log.retained, 1.0, accuracy: 1e-12)
        XCTAssertEqual(
            WateringCalculationService.capacityPercent(retained: log.retained, maxRetentionCapacity: plant.maxRetentionCapacity),
            50.0,
            accuracy: 1e-9
        )
    }

    func test_edit_nameMustStayUniqueWithinGrow() throws {
        let context = try makeContext()
        let plant = try makePlantWithLogs(in: context)
        let other = Plant(plantName: "Plant 2", potSize: "1 gal", mediumType: "soil", maxRetentionCapacity: 1.5, grow: plant.grow)
        context.insert(other)
        try context.save()

        let vm = PlantFormViewModel(mode: .edit(plant))
        vm.configure(modelContext: context, waterUnit: .liters)
        XCTAssertTrue(vm.validate(), "a plant may keep its own name")

        vm.plantName = "plant 2"
        XCTAssertFalse(vm.validate())
        XCTAssertEqual(vm.validationError, Strings.plantNameDuplicate)
    }

    func test_edit_keepsLegacyGoalUntilChanged() throws {
        // Goals above 50% were allowed before; an unchanged one is kept.
        let context = try makeContext()
        let plant = try makePlantWithLogs(in: context, goal: 90)
        let vm = PlantFormViewModel(mode: .edit(plant))
        vm.configure(modelContext: context, waterUnit: .liters)
        XCTAssertEqual(vm.goalRunoffPercentText, "90")
        XCTAssertTrue(vm.validate())

        vm.goalRunoffPercentText = "60"
        XCTAssertFalse(vm.validate())
        XCTAssertEqual(vm.validationError, Strings.goalRunoffRange)
    }
}
