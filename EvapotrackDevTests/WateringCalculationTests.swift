// WateringCalculationTests.swift
// EvapotrackDevTests
//
// Tests for WateringCalculationService: capacity percent,
// interval hours recalculation.

import XCTest
@testable import EvapotrackDev

final class WateringCalculationTests: XCTestCase {

    let fixedNow = Date(timeIntervalSince1970: 1_740_000_000)

    // MARK: - Capacity Percent

    func test_capacityPercent_normalCase_50percent() {
        let result = WateringCalculationService.capacityPercent(retained: 0.5, maxRetentionCapacity: 1.0)
        XCTAssertEqual(result, 50.0, accuracy: 0.001)
    }

    func test_capacityPercent_fullCapacity_returns100() {
        let result = WateringCalculationService.capacityPercent(retained: 1.0, maxRetentionCapacity: 1.0)
        XCTAssertEqual(result, 100.0, accuracy: 0.001)
    }

    func test_capacityPercent_exceedsCapacity_cappedAt105() {
        let result = WateringCalculationService.capacityPercent(retained: 1.5, maxRetentionCapacity: 1.0)
        XCTAssertEqual(result, 105.0, accuracy: 0.001)
    }

    func test_capacityPercent_zeroMaxRetention_returnsZero() {
        let result = WateringCalculationService.capacityPercent(retained: 0.5, maxRetentionCapacity: 0.0)
        XCTAssertEqual(result, 0.0, accuracy: 0.001)
    }

    func test_capacityPercent_negativeMaxRetention_returnsZero() {
        let result = WateringCalculationService.capacityPercent(retained: 0.5, maxRetentionCapacity: -1.0)
        XCTAssertEqual(result, 0.0, accuracy: 0.001)
    }

    func test_capacityPercent_zeroRetained_returnsZero() {
        let result = WateringCalculationService.capacityPercent(retained: 0.0, maxRetentionCapacity: 1.0)
        XCTAssertEqual(result, 0.0, accuracy: 0.001)
    }

    // MARK: - Recalculate Interval Hours

    func test_recalculateIntervalHours_emptyArray_noOp() {
        var logs: [WateringLog] = []
        WateringCalculationService.recalculateIntervalHours(for: logs)
        XCTAssertTrue(logs.isEmpty)
    }

    func test_recalculateIntervalHours_singleLog_nilInterval() {
        let log = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: fixedNow)
        var logs = [log]
        WateringCalculationService.recalculateIntervalHours(for: logs)
        XCTAssertNil(log.intervalHours)
    }

    func test_recalculateIntervalHours_twoLogs_sequential() {
        let date0 = fixedNow.addingTimeInterval(-24 * 3600)
        let log0 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: date0)
        let log1 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: fixedNow)
        var logs = [log0, log1]
        WateringCalculationService.recalculateIntervalHours(for: logs)
        XCTAssertNil(log0.intervalHours)
        XCTAssertEqual(log1.intervalHours!, 24.0, accuracy: 0.001)
    }

    func test_recalculateIntervalHours_threeLogs_sequential() {
        let date0 = fixedNow.addingTimeInterval(-48 * 3600)
        let date1 = fixedNow.addingTimeInterval(-24 * 3600)
        let log0 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: date0)
        let log1 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: date1)
        let log2 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: fixedNow)
        var logs = [log0, log1, log2]
        WateringCalculationService.recalculateIntervalHours(for: logs)
        XCTAssertNil(log0.intervalHours)
        XCTAssertEqual(log1.intervalHours!, 24.0, accuracy: 0.001)
        XCTAssertEqual(log2.intervalHours!, 24.0, accuracy: 0.001)
    }

    func test_recalculateIntervalHours_outOfOrder_sortsByDate() {
        let date0 = fixedNow.addingTimeInterval(-48 * 3600)
        let date1 = fixedNow.addingTimeInterval(-24 * 3600)
        let log0 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: date0)
        let log1 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: date1)
        let log2 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: fixedNow)
        // Pass in scrambled order
        var logs = [log2, log0, log1]
        WateringCalculationService.recalculateIntervalHours(for: logs)
        XCTAssertNil(log0.intervalHours)
        XCTAssertEqual(log1.intervalHours!, 24.0, accuracy: 0.001)
        XCTAssertEqual(log2.intervalHours!, 24.0, accuracy: 0.001)
    }

    func test_recalculateIntervalHours_unevenIntervals() {
        let date0 = fixedNow.addingTimeInterval(-72 * 3600)
        let date1 = fixedNow.addingTimeInterval(-24 * 3600)
        let log0 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: date0)
        let log1 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: date1)
        let log2 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: fixedNow)
        var logs = [log0, log1, log2]
        WateringCalculationService.recalculateIntervalHours(for: logs)
        XCTAssertNil(log0.intervalHours)
        XCTAssertEqual(log1.intervalHours!, 48.0, accuracy: 0.001)
        XCTAssertEqual(log2.intervalHours!, 24.0, accuracy: 0.001)
    }

    func test_recalculateIntervalHours_sameDateTime_zeroInterval() {
        let log0 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: fixedNow)
        let log1 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: fixedNow)
        var logs = [log0, log1]
        WateringCalculationService.recalculateIntervalHours(for: logs)
        // One gets nil (first in sort), other gets 0.0
        let sorted = [log0, log1].sorted { $0.dateTime < $1.dateTime }
        XCTAssertNil(sorted[0].intervalHours)
        XCTAssertEqual(sorted[1].intervalHours!, 0.0, accuracy: 0.001)
    }

    func test_recalculateIntervalHours_afterDeletion_recalculates() {
        let date0 = fixedNow.addingTimeInterval(-48 * 3600)
        let date1 = fixedNow.addingTimeInterval(-24 * 3600)
        let log0 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: date0)
        let log1 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: date1)
        let log2 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: fixedNow)
        // Remove middle log (simulate deletion)
        var logs = [log0, log2]
        WateringCalculationService.recalculateIntervalHours(for: logs)
        XCTAssertNil(log0.intervalHours)
        XCTAssertEqual(log2.intervalHours!, 48.0, accuracy: 0.001)
    }

    func test_recalculateIntervalHours_overwritesPreviousValues() {
        let date0 = fixedNow.addingTimeInterval(-24 * 3600)
        let log0 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: date0, intervalHours: 999.0)
        let log1 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: fixedNow, intervalHours: 999.0)
        var logs = [log0, log1]
        WateringCalculationService.recalculateIntervalHours(for: logs)
        XCTAssertNil(log0.intervalHours)
        XCTAssertEqual(log1.intervalHours!, 24.0, accuracy: 0.001)
    }

    func test_recalculateIntervalHours_nonWholeHours() {
        let date0 = fixedNow.addingTimeInterval(-36 * 3600)
        let log0 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: date0)
        let log1 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: fixedNow)
        var logs = [log0, log1]
        WateringCalculationService.recalculateIntervalHours(for: logs)
        XCTAssertNil(log0.intervalHours)
        XCTAssertEqual(log1.intervalHours!, 36.0, accuracy: 0.001)
    }

    func test_recalculateIntervalHours_fourLogs_24hApart() {
        let log0 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: fixedNow.addingTimeInterval(-72 * 3600))
        let log1 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: fixedNow.addingTimeInterval(-48 * 3600))
        let log2 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: fixedNow.addingTimeInterval(-24 * 3600))
        let log3 = WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: fixedNow)
        var logs = [log0, log1, log2, log3]
        WateringCalculationService.recalculateIntervalHours(for: logs)
        XCTAssertNil(log0.intervalHours)
        XCTAssertEqual(log1.intervalHours!, 24.0, accuracy: 0.001)
        XCTAssertEqual(log2.intervalHours!, 24.0, accuracy: 0.001)
        XCTAssertEqual(log3.intervalHours!, 24.0, accuracy: 0.001)
    }
}
