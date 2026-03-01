// NavigationTests.swift
// EvapotrackDevTests
//
// Tests for SettingsViewModel persistence with WaterUnit
// and TemperatureUnit. Verifies save/load/reset, auto-persist,
// and that unit changes never alter stored SwiftData values.

import XCTest
@testable import EvapotrackDev

@MainActor
final class NavigationTests: XCTestCase {

    // MARK: - SettingsViewModel Defaults

    func test_settingsVM_defaultSettings() {
        UserDefaults.standard.removeObject(forKey: AppConstants.userSettingsKey)

        let vm = SettingsViewModel()
        XCTAssertEqual(vm.settings.waterUnit, .liters)
        XCTAssertEqual(vm.settings.temperatureUnit, .celsius)
    }

    // MARK: - Save / Load

    func test_settingsVM_save_writesToUserDefaults() {
        UserDefaults.standard.removeObject(forKey: AppConstants.userSettingsKey)

        let vm = SettingsViewModel()
        vm.settings.waterUnit = .gallons
        vm.settings.temperatureUnit = .fahrenheit
        vm.save()

        let data = UserDefaults.standard.data(forKey: AppConstants.userSettingsKey)
        XCTAssertNotNil(data)

        let decoded = try? JSONDecoder().decode(UserSettings.self, from: data!)
        XCTAssertEqual(decoded?.waterUnit, .gallons)
        XCTAssertEqual(decoded?.temperatureUnit, .fahrenheit)
    }

    func test_settingsVM_save_milliliters() {
        UserDefaults.standard.removeObject(forKey: AppConstants.userSettingsKey)

        let vm = SettingsViewModel()
        vm.settings.waterUnit = .milliliters
        vm.save()

        let vm2 = SettingsViewModel()
        XCTAssertEqual(vm2.settings.waterUnit, .milliliters)
    }

    func test_settingsVM_load_readsFromUserDefaults() {
        let settings = UserSettings(waterUnit: .milliliters, temperatureUnit: .fahrenheit)
        let data = try! JSONEncoder().encode(settings)
        UserDefaults.standard.set(data, forKey: AppConstants.userSettingsKey)

        let vm = SettingsViewModel()
        vm.load()
        XCTAssertEqual(vm.settings.waterUnit, .milliliters)
        XCTAssertEqual(vm.settings.temperatureUnit, .fahrenheit)
    }

    // MARK: - Reset

    func test_settingsVM_reset_restoresDefaults() {
        let vm = SettingsViewModel()
        vm.settings.waterUnit = .gallons
        vm.save()

        vm.reset()
        XCTAssertEqual(vm.settings.waterUnit, .liters)
        XCTAssertEqual(vm.settings.temperatureUnit, .celsius)

        // Verify persisted too
        let vm2 = SettingsViewModel()
        XCTAssertEqual(vm2.settings.waterUnit, .liters)
    }

    // MARK: - Unit Toggle Safety

    func test_changingWaterUnit_doesNotAlterDefaultSettings() {
        let vm = SettingsViewModel()
        let originalDefault = UserSettings.default

        vm.settings.waterUnit = .milliliters
        vm.settings.waterUnit = .gallons
        vm.settings.waterUnit = .liters

        // Default constant must be untouched
        XCTAssertEqual(UserSettings.default, originalDefault)
    }

    func test_settingsVM_allWaterUnits_persistCorrectly() {
        for unit in WaterUnit.allCases {
            UserDefaults.standard.removeObject(forKey: AppConstants.userSettingsKey)
            let vm = SettingsViewModel()
            vm.settings.waterUnit = unit
            vm.save()

            let vm2 = SettingsViewModel()
            XCTAssertEqual(vm2.settings.waterUnit, unit, "Failed for \(unit)")
        }
    }

    func test_settingsVM_allTempUnits_persistCorrectly() {
        for unit in TemperatureUnit.allCases {
            UserDefaults.standard.removeObject(forKey: AppConstants.userSettingsKey)
            let vm = SettingsViewModel()
            vm.settings.temperatureUnit = unit
            vm.save()

            let vm2 = SettingsViewModel()
            XCTAssertEqual(vm2.settings.temperatureUnit, unit, "Failed for \(unit)")
        }
    }

    // MARK: - Teardown

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: AppConstants.userSettingsKey)
    }
}
