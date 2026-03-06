// WateringCalculationTests.swift
// EvapotrackDevTests
//
// Tests for WateringCalculationService: interval computation,
// status, history blending, average volume, and interval hours.

import XCTest
@testable import EvapotrackDev

final class WateringCalculationTests: XCTestCase {

    let fixedNow = Date(timeIntervalSince1970: 1_740_000_000)
    lazy var dateProvider = MockDateProvider(fixedDate: fixedNow)

    let referencePot = 15.0
    let referenceVolume = 0.25

    // MARK: - Base Interval per Medium Type

    func test_computeInterval_soil_indoor_reference() {
        let result = WateringCalculationService.computeRecommendedInterval(
            plantType: "soil", potDiameterCm: referencePot, isIndoor: true, averageVolumeLiters: referenceVolume
        )
        // base=7, pot=1.0, indoor=1.2, vol=1.0 → 8.4
        XCTAssertEqual(result, 8.4, accuracy: 0.1)
    }

    func test_computeInterval_perlite_indoor_reference() {
        let result = WateringCalculationService.computeRecommendedInterval(
            plantType: "perlite", potDiameterCm: referencePot, isIndoor: true, averageVolumeLiters: referenceVolume
        )
        // base=4, indoor=1.2 → 4.8
        XCTAssertEqual(result, 4.8, accuracy: 0.1)
    }

    func test_computeInterval_unknownType_usesDefaultBase() {
        let result = WateringCalculationService.computeRecommendedInterval(
            plantType: "alien_plant", potDiameterCm: referencePot, isIndoor: true, averageVolumeLiters: referenceVolume
        )
        // base=7 (default), indoor=1.2 → 8.4
        XCTAssertEqual(result, 8.4, accuracy: 0.1)
    }

    // MARK: - Pot Size Modifier

    func test_computeInterval_largePot_increasesInterval() {
        let large = WateringCalculationService.computeRecommendedInterval(
            plantType: "soil", potDiameterCm: 30.0, isIndoor: true, averageVolumeLiters: referenceVolume
        )
        let reference = WateringCalculationService.computeRecommendedInterval(
            plantType: "soil", potDiameterCm: referencePot, isIndoor: true, averageVolumeLiters: referenceVolume
        )
        XCTAssertGreaterThan(large, reference)
    }

    func test_computeInterval_smallPot_decreasesInterval() {
        let small = WateringCalculationService.computeRecommendedInterval(
            plantType: "soil", potDiameterCm: 5.0, isIndoor: true, averageVolumeLiters: referenceVolume
        )
        let reference = WateringCalculationService.computeRecommendedInterval(
            plantType: "soil", potDiameterCm: referencePot, isIndoor: true, averageVolumeLiters: referenceVolume
        )
        XCTAssertLessThan(small, reference)
    }

    // MARK: - Indoor/Outdoor Modifier

    func test_computeInterval_indoor_increasesVsOutdoor() {
        let indoor = WateringCalculationService.computeRecommendedInterval(
            plantType: "soil", potDiameterCm: referencePot, isIndoor: true, averageVolumeLiters: referenceVolume
        )
        let outdoor = WateringCalculationService.computeRecommendedInterval(
            plantType: "soil", potDiameterCm: referencePot, isIndoor: false, averageVolumeLiters: referenceVolume
        )
        XCTAssertGreaterThan(indoor, outdoor)
    }

    // MARK: - Volume Modifier

    func test_computeInterval_highVolume_increasesInterval() {
        let high = WateringCalculationService.computeRecommendedInterval(
            plantType: "soil", potDiameterCm: referencePot, isIndoor: true, averageVolumeLiters: 2.0
        )
        let reference = WateringCalculationService.computeRecommendedInterval(
            plantType: "soil", potDiameterCm: referencePot, isIndoor: true, averageVolumeLiters: referenceVolume
        )
        XCTAssertGreaterThan(high, reference)
    }

    // MARK: - Clamping

    func test_computeInterval_clampedToMinimum1Day() {
        let result = WateringCalculationService.computeRecommendedInterval(
            plantType: "perlite", potDiameterCm: 1.0, isIndoor: false, averageVolumeLiters: 0.001
        )
        XCTAssertGreaterThanOrEqual(result, 1.0)
    }

    func test_computeInterval_clampedToMaximum60Days() {
        let result = WateringCalculationService.computeRecommendedInterval(
            plantType: "soil", potDiameterCm: 200.0, isIndoor: true, averageVolumeLiters: 100.0
        )
        XCTAssertLessThanOrEqual(result, 60.0)
    }

    // MARK: - Plant Status

    func test_plantStatus_neverWatered() {
        let status = WateringCalculationService.plantStatus(
            lastWateredDate: nil, recommendedIntervalDays: 7.0, dateProvider: dateProvider
        )
        XCTAssertEqual(status, .neverWatered)
    }

    func test_plantStatus_wateredToday_isHealthy() {
        let status = WateringCalculationService.plantStatus(
            lastWateredDate: fixedNow, recommendedIntervalDays: 7.0, dateProvider: dateProvider
        )
        if case .healthy(let days) = status {
            XCTAssertEqual(days, 7)
        } else {
            XCTFail("Expected .healthy, got \(status)")
        }
    }

    func test_plantStatus_dueSoon_1day() {
        let sixDaysAgo = Calendar.current.date(byAdding: .day, value: -6, to: fixedNow)!
        let status = WateringCalculationService.plantStatus(
            lastWateredDate: sixDaysAgo, recommendedIntervalDays: 7.0, dateProvider: dateProvider
        )
        XCTAssertEqual(status, .dueSoon(daysRemaining: 1))
    }

    func test_plantStatus_dueToday() {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: fixedNow)!
        let status = WateringCalculationService.plantStatus(
            lastWateredDate: sevenDaysAgo, recommendedIntervalDays: 7.0, dateProvider: dateProvider
        )
        XCTAssertEqual(status, .dueSoon(daysRemaining: 0))
    }

    func test_plantStatus_overdue3Days() {
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: fixedNow)!
        let status = WateringCalculationService.plantStatus(
            lastWateredDate: tenDaysAgo, recommendedIntervalDays: 7.0, dateProvider: dateProvider
        )
        XCTAssertEqual(status, .overdue(daysOverdue: 3))
    }

    // MARK: - Next Watering Date

    func test_nextWateringDate_addsIntervalToLastWatered() {
        let next = WateringCalculationService.nextWateringDate(
            lastWateredDate: fixedNow, recommendedIntervalDays: 7.0
        )
        let daysDiff = Date.daysBetween(start: fixedNow, end: next)
        XCTAssertEqual(daysDiff, 7)
    }

    // MARK: - Days Until Next Watering

    func test_daysUntilNextWatering_futureDate_positive() {
        let days = WateringCalculationService.daysUntilNextWatering(
            lastWateredDate: fixedNow, recommendedIntervalDays: 7.0, dateProvider: dateProvider
        )
        XCTAssertEqual(days, 7)
    }

    func test_daysUntilNextWatering_pastDate_negative() {
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: fixedNow)!
        let days = WateringCalculationService.daysUntilNextWatering(
            lastWateredDate: tenDaysAgo, recommendedIntervalDays: 7.0, dateProvider: dateProvider
        )
        XCTAssertEqual(days, -3)
    }

    // MARK: - History-Based Recalculation

    func test_recalculateFromHistory_lessThan3Events_usesFormula() {
        let events = [
            WateringEvent(date: fixedNow, volumeLiters: 0.25),
            WateringEvent(date: Calendar.current.date(byAdding: .day, value: -7, to: fixedNow)!, volumeLiters: 0.25)
        ]
        let result = WateringCalculationService.recalculateIntervalFromHistory(
            events: events, plantType: "soil", potDiameterCm: 15.0, isIndoor: true
        )
        let formulaOnly = WateringCalculationService.computeRecommendedInterval(
            plantType: "soil", potDiameterCm: 15.0, isIndoor: true, averageVolumeLiters: 0.25
        )
        XCTAssertEqual(result, formulaOnly, accuracy: 0.1)
    }

    func test_recalculateFromHistory_3PlusEvents_blendsWithActual() {
        let events = (0..<4).map { i in
            WateringEvent(
                date: Calendar.current.date(byAdding: .day, value: -i * 5, to: fixedNow)!,
                volumeLiters: 0.25
            )
        }
        let result = WateringCalculationService.recalculateIntervalFromHistory(
            events: events, plantType: "soil", potDiameterCm: 15.0, isIndoor: true
        )
        let formulaOnly = WateringCalculationService.computeRecommendedInterval(
            plantType: "soil", potDiameterCm: 15.0, isIndoor: true, averageVolumeLiters: 0.25
        )
        XCTAssertNotEqual(result, formulaOnly, accuracy: 0.01)
        let expectedBlend = formulaOnly * 0.4 + 5.0 * 0.6
        XCTAssertEqual(result, expectedBlend, accuracy: 0.2)
    }

    func test_recalculateFromHistory_emptyHistory_usesFormula() {
        let result = WateringCalculationService.recalculateIntervalFromHistory(
            events: [], plantType: "soil", potDiameterCm: 15.0, isIndoor: true
        )
        let formulaOnly = WateringCalculationService.computeRecommendedInterval(
            plantType: "soil", potDiameterCm: 15.0, isIndoor: true, averageVolumeLiters: 0.25
        )
        XCTAssertEqual(result, formulaOnly, accuracy: 0.1)
    }

    // MARK: - Average Volume

    func test_averageVolume_singleEvent_returnsThatVolume() {
        let events = [WateringEvent(volumeLiters: 0.5)]
        XCTAssertEqual(WateringCalculationService.averageVolume(from: events), 0.5, accuracy: 0.001)
    }

    func test_averageVolume_multipleEvents_returnsAverage() {
        let events = [
            WateringEvent(volumeLiters: 0.3),
            WateringEvent(volumeLiters: 0.5),
            WateringEvent(volumeLiters: 0.4)
        ]
        XCTAssertEqual(WateringCalculationService.averageVolume(from: events), 0.4, accuracy: 0.001)
    }

    func test_averageVolume_emptyEvents_returnsZero() {
        XCTAssertEqual(WateringCalculationService.averageVolume(from: []), 0.0)
    }

    func test_averageVolume_respectsLimit() {
        let events = (0..<5).map { i in
            WateringEvent(
                date: Calendar.current.date(byAdding: .day, value: -i, to: fixedNow)!,
                volumeLiters: Double(i + 1) * 0.1
            )
        }
        let avg = WateringCalculationService.averageVolume(from: events, limit: 2)
        // Most recent 2: day 0 (0.1), day -1 (0.2) → avg = 0.15
        XCTAssertEqual(avg, 0.15, accuracy: 0.01)
    }

    // MARK: - Chronological Ordering

    func test_eventsAreSortedNewestFirst() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: fixedNow)!
        let midDate = Calendar.current.date(byAdding: .day, value: -5, to: fixedNow)!
        let newDate = fixedNow

        var events = [
            WateringEvent(date: midDate, volumeLiters: 0.2),
            WateringEvent(date: oldDate, volumeLiters: 0.1),
            WateringEvent(date: newDate, volumeLiters: 0.3)
        ]
        events.sort { $0.date > $1.date }

        XCTAssertEqual(events[0].date, newDate)
        XCTAssertEqual(events[1].date, midDate)
        XCTAssertEqual(events[2].date, oldDate)
    }

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
