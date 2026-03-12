// ValidationTests.swift
// EvapotrackDevTests
//
// Tests for all validation rules in Validators.

import XCTest
@testable import EvapotrackDev

final class ValidationTests: XCTestCase {

    // MARK: - Plant Name

    func test_plantName_empty_isInvalid() {
        XCTAssertFalse(Validators.isValidPlantName(""))
    }

    func test_plantName_whitespaceOnly_isInvalid() {
        XCTAssertFalse(Validators.isValidPlantName("   "))
    }

    func test_plantName_singleChar_isValid() {
        XCTAssertTrue(Validators.isValidPlantName("A"))
    }

    func test_plantName_50chars_isValid() {
        let name = String(repeating: "a", count: 50)
        XCTAssertTrue(Validators.isValidPlantName(name))
    }

    func test_plantName_51chars_isInvalid() {
        let name = String(repeating: "a", count: 51)
        XCTAssertFalse(Validators.isValidPlantName(name))
    }

    func test_plantName_normalName_isValid() {
        XCTAssertTrue(Validators.isValidPlantName("My Basil Plant"))
    }

    // MARK: - Pot Size

    func test_potSize_empty_isInvalid() {
        XCTAssertFalse(Validators.isValidPotSize(""))
    }

    func test_potSize_whitespace_isInvalid() {
        XCTAssertFalse(Validators.isValidPotSize("   "))
    }

    func test_potSize_valid() {
        XCTAssertTrue(Validators.isValidPotSize("6 inch"))
    }

    // MARK: - Medium Type

    func test_mediumType_empty_isInvalid() {
        XCTAssertFalse(Validators.isValidMediumType(""))
    }

    func test_mediumType_valid() {
        XCTAssertTrue(Validators.isValidMediumType("soil"))
    }

    // MARK: - Max Retention

    func test_maxRetention_0_isInvalid() {
        XCTAssertFalse(Validators.isValidMaxRetention(0))
    }

    func test_maxRetention_0_001_isValid() {
        XCTAssertTrue(Validators.isValidMaxRetention(0.001))
    }

    func test_maxRetention_100_isValid() {
        XCTAssertTrue(Validators.isValidMaxRetention(100.0))
    }

    func test_maxRetention_101_isInvalid() {
        XCTAssertFalse(Validators.isValidMaxRetention(100.1))
    }

    // MARK: - Volume (Water Added)

    func test_volume_0_isInvalid() {
        XCTAssertFalse(Validators.isValidVolume(0))
    }

    func test_volume_0_001_isValid() {
        XCTAssertTrue(Validators.isValidVolume(0.001))
    }

    func test_volume_100_isValid() {
        XCTAssertTrue(Validators.isValidVolume(100.0))
    }

    func test_volume_100_1_isInvalid() {
        XCTAssertFalse(Validators.isValidVolume(100.1))
    }

    func test_volume_negative_isInvalid() {
        XCTAssertFalse(Validators.isValidVolume(-1.0))
    }

    // MARK: - Runoff

    func test_runoff_zero_isValid() {
        XCTAssertTrue(Validators.isValidRunoff(0, waterAdded: 1.0))
    }

    func test_runoff_lessThanWaterAdded_isValid() {
        XCTAssertTrue(Validators.isValidRunoff(0.3, waterAdded: 1.0))
    }

    func test_runoff_equalToWaterAdded_isInvalid() {
        XCTAssertFalse(Validators.isValidRunoff(1.0, waterAdded: 1.0))
    }

    func test_runoff_greaterThanWaterAdded_isInvalid() {
        XCTAssertFalse(Validators.isValidRunoff(1.5, waterAdded: 1.0))
    }

    func test_runoff_negative_isInvalid() {
        XCTAssertFalse(Validators.isValidRunoff(-0.1, waterAdded: 1.0))
    }

    // MARK: - Humidity

    func test_humidity_0_isValid() {
        XCTAssertTrue(Validators.isValidHumidity(0))
    }

    func test_humidity_100_isValid() {
        XCTAssertTrue(Validators.isValidHumidity(100))
    }

    func test_humidity_negative_isInvalid() {
        XCTAssertFalse(Validators.isValidHumidity(-1))
    }

    func test_humidity_101_isInvalid() {
        XCTAssertFalse(Validators.isValidHumidity(101))
    }

    // MARK: - Date

    func test_date_pastDate_isValid() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date.now)!
        XCTAssertTrue(Validators.isNotFutureDate(yesterday, now: Date.now))
    }

    func test_date_now_isValid() {
        let now = Date.now
        XCTAssertTrue(Validators.isNotFutureDate(now, now: now))
    }

    func test_date_futureDate_isInvalid() {
        let fixedNow = Date(timeIntervalSince1970: 1_700_000_000)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: fixedNow)!
        XCTAssertFalse(Validators.isNotFutureDate(tomorrow, now: fixedNow))
    }

    // MARK: - Temperature

    func test_temperature_zero_isValid() {
        XCTAssertTrue(Validators.isValidTemperature(0))
    }

    func test_temperature_negative_inRange_isValid() {
        XCTAssertTrue(Validators.isValidTemperature(-10.0))
    }

    func test_temperature_belowRange_isInvalid() {
        XCTAssertFalse(Validators.isValidTemperature(-51.0))
    }

    func test_temperature_aboveRange_isInvalid() {
        XCTAssertFalse(Validators.isValidTemperature(61.0))
    }

    func test_temperature_positive_isValid() {
        XCTAssertTrue(Validators.isValidTemperature(22.5))
    }

    func test_temperature_boundaries_areValid() {
        XCTAssertTrue(Validators.isValidTemperature(-50))
        XCTAssertTrue(Validators.isValidTemperature(60))
    }

    // MARK: - Grow Name

    func test_growName_empty_isInvalid() {
        XCTAssertFalse(Validators.isValidGrowName(""))
    }

    func test_growName_whitespaceOnly_isInvalid() {
        XCTAssertFalse(Validators.isValidGrowName("   "))
    }

    func test_growName_singleChar_isValid() {
        XCTAssertTrue(Validators.isValidGrowName("A"))
    }

    func test_growName_50chars_isValid() {
        let name = String(repeating: "g", count: 50)
        XCTAssertTrue(Validators.isValidGrowName(name))
    }

    func test_growName_51chars_isInvalid() {
        let name = String(repeating: "g", count: 51)
        XCTAssertFalse(Validators.isValidGrowName(name))
    }

    // MARK: - ValidationService Error Messages

    func test_validateGrowName_valid_returnsValid() {
        XCTAssertEqual(ValidationService.validateGrowName("My Grow"), .valid)
    }

    func test_validateGrowName_empty_returnsInvalidWithMessage() {
        XCTAssertEqual(
            ValidationService.validateGrowName(""),
            .invalid("Grow name must be 1–\(AppConstants.maxGrowNameLength) characters and not blank.")
        )
    }

    func test_validatePlantName_valid_returnsValid() {
        XCTAssertEqual(ValidationService.validatePlantName("Basil"), .valid)
    }

    func test_validatePlantName_empty_returnsInvalidWithMessage() {
        XCTAssertEqual(
            ValidationService.validatePlantName(""),
            .invalid("Plant name must be 1–\(AppConstants.maxPlantNameLength) characters and not blank.")
        )
    }

    func test_validatePotSize_valid_returnsValid() {
        XCTAssertEqual(ValidationService.validatePotSize("6 inch"), .valid)
    }

    func test_validatePotSize_blank_returnsInvalidWithMessage() {
        XCTAssertEqual(
            ValidationService.validatePotSize("   "),
            .invalid("Pot size must not be blank.")
        )
    }

    func test_validateMediumType_valid_returnsValid() {
        XCTAssertEqual(ValidationService.validateMediumType("soil"), .valid)
    }

    func test_validateMediumType_blank_returnsInvalidWithMessage() {
        XCTAssertEqual(
            ValidationService.validateMediumType(""),
            .invalid("Medium type must not be blank.")
        )
    }

    func test_validateMaxRetention_valid_returnsValid() {
        XCTAssertEqual(ValidationService.validateMaxRetention(0.5), .valid)
    }

    func test_validateMaxRetention_zero_returnsInvalidWithMessage() {
        XCTAssertEqual(
            ValidationService.validateMaxRetention(0.0),
            .invalid("Max retention capacity must be between 0.001 and 100 liters.")
        )
    }

    func test_validateWaterAdded_valid_returnsValid() {
        XCTAssertEqual(ValidationService.validateWaterAdded(1.0), .valid)
    }

    func test_validateWaterAdded_zero_returnsInvalidWithMessage() {
        XCTAssertEqual(
            ValidationService.validateWaterAdded(0.0),
            .invalid("Water added must be between 0.001 and 100 liters.")
        )
    }

    func test_validateRunoff_valid_returnsValid() {
        XCTAssertEqual(ValidationService.validateRunoff(0.3, waterAdded: 1.0), .valid)
    }

    func test_validateRunoff_equalToWater_returnsInvalidWithMessage() {
        XCTAssertEqual(
            ValidationService.validateRunoff(1.0, waterAdded: 1.0),
            .invalid("Runoff must be ≥ 0 and less than water added.")
        )
    }

    func test_validateTemperature_valid_returnsValid() {
        XCTAssertEqual(ValidationService.validateTemperature(22.0), .valid)
    }

    func test_validateTemperature_zero_returnsValid() {
        XCTAssertEqual(ValidationService.validateTemperature(0.0), .valid)
    }

    func test_validateTemperature_outOfRange_returnsInvalidWithMessage() {
        XCTAssertEqual(
            ValidationService.validateTemperature(-51.0),
            .invalid("Temperature must be between -50 and 60 °C.")
        )
    }

    func test_validateHumidity_valid_returnsValid() {
        XCTAssertEqual(ValidationService.validateHumidity(50.0), .valid)
    }

    func test_validateHumidity_negative_returnsInvalidWithMessage() {
        XCTAssertEqual(
            ValidationService.validateHumidity(-1.0),
            .invalid("Humidity must be between 0 and 100%.")
        )
    }

    func test_validateDate_valid_returnsValid() {
        let fixedNow = Date(timeIntervalSince1970: 1_740_000_000)
        let yesterday = fixedNow.addingTimeInterval(-86400)
        XCTAssertEqual(ValidationService.validateDate(yesterday, now: fixedNow), .valid)
    }

    func test_validateDate_future_returnsInvalidWithMessage() {
        let fixedNow = Date(timeIntervalSince1970: 1_740_000_000)
        let tomorrow = fixedNow.addingTimeInterval(86400)
        XCTAssertEqual(
            ValidationService.validateDate(tomorrow, now: fixedNow),
            .invalid("Date cannot be in the future.")
        )
    }
}
