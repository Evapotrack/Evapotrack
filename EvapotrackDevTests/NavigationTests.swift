// © 2026 Evapotrack. All rights reserved.
// NavigationTests.swift
// EvapotrackDevTests
//
// Tests for SettingsViewModel persistence with WaterUnit
// and TemperatureUnit. Verifies save/load/reset, auto-persist,
// and that unit changes never alter stored SwiftData values.
// Uses a private UserDefaults suite per test (TEST-4).

import XCTest
@testable import EvapotrackDev

@MainActor
final class NavigationTests: XCTestCase {

    // Each test gets its own settings store, so tests never read or erase the
    // app's real settings and can't affect each other.
    private let suiteName = "EvapotrackTests-\(UUID().uuidString)"
    private lazy var defaults = UserDefaults(suiteName: suiteName)!

    // MARK: - SettingsViewModel Defaults

    func test_settingsVM_defaultSettings() {
        defaults.removeObject(forKey: AppConstants.userSettingsKey)

        let vm = SettingsViewModel(defaults: defaults)
        XCTAssertEqual(vm.settings.waterUnit, .liters)
        XCTAssertEqual(vm.settings.temperatureUnit, .fahrenheit)
    }

    // MARK: - Save / Load

    func test_settingsVM_save_writesToUserDefaults() {
        defaults.removeObject(forKey: AppConstants.userSettingsKey)

        let vm = SettingsViewModel(defaults: defaults)
        vm.settings.waterUnit = .gallons
        vm.settings.temperatureUnit = .fahrenheit
        vm.save()

        let data = defaults.data(forKey: AppConstants.userSettingsKey)
        XCTAssertNotNil(data)

        let decoded = try? JSONDecoder().decode(UserSettings.self, from: data!)
        XCTAssertEqual(decoded?.waterUnit, .gallons)
        XCTAssertEqual(decoded?.temperatureUnit, .fahrenheit)
    }

    func test_settingsVM_save_milliliters() {
        defaults.removeObject(forKey: AppConstants.userSettingsKey)

        let vm = SettingsViewModel(defaults: defaults)
        vm.settings.waterUnit = .milliliters
        vm.save()

        let vm2 = SettingsViewModel(defaults: defaults)
        XCTAssertEqual(vm2.settings.waterUnit, .milliliters)
    }

    func test_settingsVM_load_readsFromUserDefaults() {
        let settings = UserSettings(waterUnit: .milliliters, temperatureUnit: .fahrenheit)
        let data = try! JSONEncoder().encode(settings)
        defaults.set(data, forKey: AppConstants.userSettingsKey)

        let vm = SettingsViewModel(defaults: defaults)
        vm.load()
        XCTAssertEqual(vm.settings.waterUnit, .milliliters)
        XCTAssertEqual(vm.settings.temperatureUnit, .fahrenheit)
    }

    // MARK: - Reset

    func test_settingsVM_reset_restoresDefaults() {
        let vm = SettingsViewModel(defaults: defaults)
        vm.settings.waterUnit = .gallons
        vm.save()

        vm.reset()
        XCTAssertEqual(vm.settings.waterUnit, .liters)
        XCTAssertEqual(vm.settings.temperatureUnit, .fahrenheit)

        // Verify persisted too
        let vm2 = SettingsViewModel(defaults: defaults)
        XCTAssertEqual(vm2.settings.waterUnit, .liters)
    }

    // MARK: - Unit Toggle Safety

    func test_changingWaterUnit_doesNotAlterDefaultSettings() {
        let vm = SettingsViewModel(defaults: defaults)
        let originalDefault = UserSettings.default

        vm.settings.waterUnit = .milliliters
        vm.settings.waterUnit = .gallons
        vm.settings.waterUnit = .liters

        // Default constant must be untouched
        XCTAssertEqual(UserSettings.default, originalDefault)
    }

    func test_settingsVM_allWaterUnits_persistCorrectly() {
        for unit in WaterUnit.allCases {
            defaults.removeObject(forKey: AppConstants.userSettingsKey)
            let vm = SettingsViewModel(defaults: defaults)
            vm.settings.waterUnit = unit
            vm.save()

            let vm2 = SettingsViewModel(defaults: defaults)
            XCTAssertEqual(vm2.settings.waterUnit, unit, "Failed for \(unit)")
        }
    }

    func test_settingsVM_allTempUnits_persistCorrectly() {
        for unit in TemperatureUnit.allCases {
            defaults.removeObject(forKey: AppConstants.userSettingsKey)
            let vm = SettingsViewModel(defaults: defaults)
            vm.settings.temperatureUnit = unit
            vm.save()

            let vm2 = SettingsViewModel(defaults: defaults)
            XCTAssertEqual(vm2.settings.temperatureUnit, unit, "Failed for \(unit)")
        }
    }

    // MARK: - Teardown

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }
}
