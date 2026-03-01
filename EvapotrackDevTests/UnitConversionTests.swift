// UnitConversionTests.swift
// EvapotrackDevTests
//
// Tests for all water and temperature conversion paths
// in UnitConversionService. Verifies bidirectional,
// deterministic, pure conversions free of drift.

import XCTest
@testable import EvapotrackDev

final class UnitConversionTests: XCTestCase {

    private let accuracy = 0.001

    // MARK: - Water: toLiters

    func test_toLiters_fromLiters_identity() {
        XCTAssertEqual(UnitConversionService.toLiters(2.5, from: .liters), 2.5)
    }

    func test_toLiters_fromMilliliters() {
        let result = UnitConversionService.toLiters(1000.0, from: .milliliters)
        XCTAssertEqual(result, 1.0, accuracy: accuracy)
    }

    func test_toLiters_fromMilliliters_500() {
        let result = UnitConversionService.toLiters(500.0, from: .milliliters)
        XCTAssertEqual(result, 0.5, accuracy: accuracy)
    }

    func test_toLiters_fromGallons() {
        let result = UnitConversionService.toLiters(1.0, from: .gallons)
        XCTAssertEqual(result, 3.785411784, accuracy: 0.0001)
    }

    // MARK: - Water: fromLiters

    func test_fromLiters_toLiters_identity() {
        XCTAssertEqual(UnitConversionService.fromLiters(2.5, to: .liters), 2.5)
    }

    func test_fromLiters_toMilliliters() {
        let result = UnitConversionService.fromLiters(1.0, to: .milliliters)
        XCTAssertEqual(result, 1000.0, accuracy: accuracy)
    }

    func test_fromLiters_toMilliliters_0_5() {
        let result = UnitConversionService.fromLiters(0.5, to: .milliliters)
        XCTAssertEqual(result, 500.0, accuracy: accuracy)
    }

    func test_fromLiters_toGallons() {
        let result = UnitConversionService.fromLiters(1.0, to: .gallons)
        XCTAssertEqual(result, 0.264172, accuracy: accuracy)
    }

    // MARK: - Temperature: toCelsius / fromCelsius

    func test_toCelsius_fromCelsius_identity() {
        XCTAssertEqual(UnitConversionService.toCelsius(25.0, from: .celsius), 25.0)
    }

    func test_toCelsius_fromFahrenheit_32() {
        XCTAssertEqual(UnitConversionService.toCelsius(32.0, from: .fahrenheit), 0.0, accuracy: accuracy)
    }

    func test_toCelsius_fromFahrenheit_212() {
        XCTAssertEqual(UnitConversionService.toCelsius(212.0, from: .fahrenheit), 100.0, accuracy: accuracy)
    }

    func test_fromCelsius_toCelsius_identity() {
        XCTAssertEqual(UnitConversionService.fromCelsius(25.0, to: .celsius), 25.0)
    }

    func test_fromCelsius_toFahrenheit_0() {
        XCTAssertEqual(UnitConversionService.fromCelsius(0.0, to: .fahrenheit), 32.0, accuracy: accuracy)
    }

    func test_fromCelsius_toFahrenheit_100() {
        XCTAssertEqual(UnitConversionService.fromCelsius(100.0, to: .fahrenheit), 212.0, accuracy: accuracy)
    }

    // MARK: - Round-Trip (reversibility)

    func test_waterRoundTrip_milliliters() {
        let original = 2.5
        let mL = UnitConversionService.fromLiters(original, to: .milliliters)
        let back = UnitConversionService.toLiters(mL, from: .milliliters)
        XCTAssertEqual(back, original, accuracy: accuracy)
    }

    func test_waterRoundTrip_gallons() {
        let original = 2.5
        let gallons = UnitConversionService.fromLiters(original, to: .gallons)
        let back = UnitConversionService.toLiters(gallons, from: .gallons)
        XCTAssertEqual(back, original, accuracy: accuracy)
    }

    func test_temperatureRoundTrip() {
        let original = 37.5
        let f = UnitConversionService.fromCelsius(original, to: .fahrenheit)
        let back = UnitConversionService.toCelsius(f, from: .fahrenheit)
        XCTAssertEqual(back, original, accuracy: accuracy)
    }

    // MARK: - Display Precision (via WaterUnit)

    func test_waterUnit_milliliters_precision0() {
        XCTAssertEqual(WaterUnit.milliliters.displayPrecision, 0)
    }

    func test_waterUnit_liters_precision2() {
        XCTAssertEqual(WaterUnit.liters.displayPrecision, 2)
    }

    func test_waterUnit_gallons_precision3() {
        XCTAssertEqual(WaterUnit.gallons.displayPrecision, 3)
    }

    func test_temperatureUnit_precision1() {
        XCTAssertEqual(TemperatureUnit.celsius.displayPrecision, 1)
        XCTAssertEqual(TemperatureUnit.fahrenheit.displayPrecision, 1)
    }

    // MARK: - DisplayFormatter

    func test_displayFormatter_water_milliliters() {
        // 0.5 L → 500 mL, 0 decimals
        let result = DisplayFormatter.water(0.5, unit: .milliliters)
        XCTAssertEqual(result, "500 mL")
    }

    func test_displayFormatter_water_liters() {
        // 0.5 L → "0.50 L", 2 decimals
        let result = DisplayFormatter.water(0.5, unit: .liters)
        XCTAssertEqual(result, "0.50 L")
    }

    func test_displayFormatter_water_gallons() {
        // 1.0 L → ~0.264 gal, 3 decimals
        let result = DisplayFormatter.water(1.0, unit: .gallons)
        XCTAssertTrue(result.hasSuffix("gal"))
        XCTAssertTrue(result.contains("0.264"))
    }

    func test_displayFormatter_temperature_celsius() {
        let result = DisplayFormatter.temperature(22.5, unit: .celsius)
        XCTAssertEqual(result, "22.5 °C")
    }

    func test_displayFormatter_temperature_fahrenheit() {
        // 0°C → 32.0°F
        let result = DisplayFormatter.temperature(0.0, unit: .fahrenheit)
        XCTAssertEqual(result, "32.0 °F")
    }

    func test_displayFormatter_percent() {
        let result = DisplayFormatter.percent(45.678)
        XCTAssertEqual(result, "45.7%")
    }

    func test_displayFormatter_intervalHours() {
        let result = DisplayFormatter.intervalHours(72.456)
        XCTAssertEqual(result, "72.5 h")
    }

    func test_displayFormatter_intervalAdaptive_hours() {
        // < 24h → show hours
        let result = DisplayFormatter.intervalAdaptive(18.5)
        XCTAssertTrue(result.contains("h"))
    }

    func test_displayFormatter_intervalAdaptive_days() {
        // >= 24h → show days
        let result = DisplayFormatter.intervalAdaptive(48.0)
        XCTAssertTrue(result.contains("d"))
    }
}
