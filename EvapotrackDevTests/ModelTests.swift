// ModelTests.swift
// EvapotrackDevTests
//
// Tests for Plant, WateringLog, and UserSettings models.

import XCTest
import SwiftData
@testable import EvapotrackDev

@MainActor
final class ModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Plant.self, WateringLog.self, configurations: config)
    }

    // MARK: - Plant Init

    func test_plant_init_setsAllProperties() {
        let plant = Plant(
            plantName: "Basil",
            potSize: "6 inch",
            mediumType: "soil",
            maxRetentionCapacity: 0.5
        )
        XCTAssertEqual(plant.plantName, "Basil")
        XCTAssertEqual(plant.potSize, "6 inch")
        XCTAssertEqual(plant.mediumType, "soil")
        XCTAssertEqual(plant.maxRetentionCapacity, 0.5)
        XCTAssertTrue(plant.wateringLogs.isEmpty)
    }

    // MARK: - WateringLog Init

    func test_wateringLog_init_computesDerivedFields() {
        let log = WateringLog(
            waterAdded: 1.0,
            runoffCollected: 0.2,
            dateTime: Date()
        )
        XCTAssertEqual(log.retained, 0.8, accuracy: 0.001)
        XCTAssertEqual(log.runoffPercent, 20.0, accuracy: 0.001)
        XCTAssertNil(log.intervalHours)
    }

    func test_wateringLog_init_withOptionalFields() {
        let log = WateringLog(
            waterAdded: 0.5,
            runoffCollected: 0.1,
            dateTime: Date(),
            temperatureCelsius: 22.5,
            humidityPercent: 65.0,
            intervalHours: 48.0
        )
        XCTAssertEqual(log.temperatureCelsius, 22.5)
        XCTAssertEqual(log.humidityPercent, 65.0)
        XCTAssertEqual(log.intervalHours, 48.0)
        XCTAssertEqual(log.retained, 0.4, accuracy: 0.001)
        XCTAssertEqual(log.runoffPercent, 20.0, accuracy: 0.001)
    }

    // MARK: - Cascade Delete

    func test_deletePlant_cascadeDeletesLogs() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let plant = Plant(plantName: "Test", potSize: "Small", mediumType: "soil", maxRetentionCapacity: 1.0)
        context.insert(plant)

        let log1 = WateringLog(waterAdded: 0.5, runoffCollected: 0.1, dateTime: Date())
        log1.plant = plant
        context.insert(log1)

        let log2 = WateringLog(waterAdded: 0.3, runoffCollected: 0.05, dateTime: Date())
        log2.plant = plant
        context.insert(log2)
        try context.save()

        let allLogs = try context.fetch(FetchDescriptor<WateringLog>())
        XCTAssertEqual(allLogs.count, 2)

        context.delete(plant)
        try context.save()

        let remainingLogs = try context.fetch(FetchDescriptor<WateringLog>())
        XCTAssertEqual(remainingLogs.count, 0)
    }

    func test_deleteLog_doesNotDeletePlant() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let plant = Plant(plantName: "Survivor", potSize: "Medium", mediumType: "perlite", maxRetentionCapacity: 0.8)
        context.insert(plant)

        let log = WateringLog(waterAdded: 0.5, runoffCollected: 0.1, dateTime: Date())
        log.plant = plant
        context.insert(log)
        try context.save()

        context.delete(log)
        try context.save()

        let remainingPlants = try context.fetch(FetchDescriptor<Plant>())
        XCTAssertEqual(remainingPlants.count, 1)
        XCTAssertEqual(remainingPlants.first?.plantName, "Survivor")
    }

    // MARK: - Selection Reset After Deletion

    /// After deleting a plant, its ID no longer resolves in the data source,
    /// so any stored selectedPlantID becomes stale. The view layer sets
    /// selectedPlantID = nil after calling deletePlant (verified by code review).
    func test_deletePlant_selectedIDNoLongerResolvable() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let plant = Plant(plantName: "Selected", potSize: "Small", mediumType: "soil", maxRetentionCapacity: 1.0)
        context.insert(plant)
        try context.save()

        let selectedID = plant.id

        // Simulate selection: ID resolves to a plant
        let service = PlantService(modelContext: context)
        let before = service.fetchAll().first(where: { $0.id == selectedID })
        XCTAssertNotNil(before)

        // Delete the plant
        service.deletePlant(plant)

        // After deletion, the selectedID no longer resolves
        let after = service.fetchAll().first(where: { $0.id == selectedID })
        XCTAssertNil(after, "Selected plant ID must not resolve after deletion")
    }

    /// After deleting a log, its ID no longer resolves in the plant's log list,
    /// so any stored selectedLogID becomes stale. The view layer sets
    /// selectedLogID = nil after calling deleteLog (verified by code review).
    func test_deleteLog_selectedIDNoLongerResolvable() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let plant = Plant(plantName: "Host", potSize: "Medium", mediumType: "perlite", maxRetentionCapacity: 0.8)
        context.insert(plant)

        let log = WateringLog(waterAdded: 0.5, runoffCollected: 0.1, dateTime: Date())
        log.plant = plant
        plant.wateringLogs.append(log)
        context.insert(log)
        try context.save()

        let selectedLogID = log.id

        // Simulate selection: ID resolves to a log
        let service = WateringLogService(modelContext: context)
        let before = service.fetchLogs(for: plant).first(where: { $0.id == selectedLogID })
        XCTAssertNotNil(before)

        // Delete the log
        service.deleteLog(log)

        // After deletion, the selectedLogID no longer resolves
        let after = service.fetchLogs(for: plant).first(where: { $0.id == selectedLogID })
        XCTAssertNil(after, "Selected log ID must not resolve after deletion")
    }

    // MARK: - UserSettings

    func test_userSettings_default_isLitersAndCelsius() {
        let settings = UserSettings.default
        XCTAssertEqual(settings.waterUnit, .liters)
        XCTAssertEqual(settings.temperatureUnit, .celsius)
    }

    func test_userSettings_codable_roundTrip() throws {
        let original = UserSettings(waterUnit: .gallons, temperatureUnit: .fahrenheit)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserSettings.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func test_userSettings_codable_roundTrip_milliliters() throws {
        let original = UserSettings(waterUnit: .milliliters, temperatureUnit: .celsius)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserSettings.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    /// Existing UserDefaults data saved before appearanceMode was added
    /// must decode without losing water/temperature unit preferences.
    func test_userSettings_codable_backwardCompatibility_missingAppearanceMode() throws {
        // Simulate JSON saved before appearanceMode existed
        let legacyJSON = """
        {"waterUnit":"gal","temperatureUnit":"°F"}
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(UserSettings.self, from: legacyJSON)
        XCTAssertEqual(decoded.waterUnit, .gallons)
        XCTAssertEqual(decoded.temperatureUnit, .fahrenheit)
        XCTAssertEqual(decoded.appearanceMode, .light, "Missing appearanceMode should default to .light")
    }

    /// Existing UserDefaults data saved with the removed "System" value
    /// must decode gracefully, falling back to .light.
    func test_userSettings_codable_backwardCompatibility_systemAppearanceMode() throws {
        let legacyJSON = """
        {"waterUnit":"L","temperatureUnit":"°C","appearanceMode":"System"}
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(UserSettings.self, from: legacyJSON)
        XCTAssertEqual(decoded.waterUnit, .liters)
        XCTAssertEqual(decoded.temperatureUnit, .celsius)
        XCTAssertEqual(decoded.appearanceMode, .light, "Removed 'System' value should fall back to .light")
    }
}
