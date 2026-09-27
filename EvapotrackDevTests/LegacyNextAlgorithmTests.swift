// © 2026 Evapotrack. All rights reserved.
// LegacyNextAlgorithmTests.swift
// EvapotrackDevTests
//
// Characterization tests for the Next algorithm shipped through 89cc8c8.
// Every case is a real watering history; expected values are what that
// algorithm produced, including the behaviors that motivated replacing it
// (lag on growing plants, zero-runoff logs treated as exact, nil after a
// fully drained watering, runaway values at high goals).

import XCTest
@testable import EvapotrackDev

final class LegacyNextAlgorithmTests: XCTestCase {

    private let accuracy = 1e-9

    private func legacy(
        _ amounts: [(water: Double, runoff: Double)],
        mrc: Double = 4.5,
        goal: Double = 15.0
    ) -> LegacyRecommendation? {
        LegacyRecommendationModel.recommend(
            WateringHistory.make(amounts),
            maxRetentionCapacity: mrc,
            goalRunoffPercent: goal
        )
    }

    // MARK: - Basic histories

    func test_noHistory_returnsNil() {
        XCTAssertNil(legacy([]))
    }

    func test_oneWatering_recommendsSameAmountAgain() throws {
        // 1.20 L in, 0.18 L out (15%) -> 1.02 L retained -> 1.02 / 0.85 = 1.20 L
        let result = try XCTUnwrap(legacy([(1.20, 0.18)]))
        XCTAssertEqual(result.next, 1.20, accuracy: accuracy)
        XCTAssertEqual(result.goalRunoff, 0.18, accuracy: accuracy)
    }

    func test_steadyHistory_isAFixedPoint() throws {
        let result = try XCTUnwrap(legacy(WateringHistory.steady(5)))
        XCTAssertEqual(result.next, 1.20, accuracy: accuracy)
    }

    func test_multipleWaterings_blendNewestWithAllTimeMean() throws {
        // retained 0.85, 1.00, 1.00 -> mean 0.95; (1.00 + 0.95) / 2 / 0.85
        let result = try XCTUnwrap(legacy([(1.00, 0.15), (1.20, 0.20), (1.10, 0.10)]))
        XCTAssertEqual(result.next, 1.147058823529412, accuracy: accuracy)
        XCTAssertEqual(result.goalRunoff, 0.17205882352941176, accuracy: accuracy)
    }

    // MARK: - Unusual last waterings

    func test_zeroRunoffLast_treatsWaterAddedAsExactRetention() throws {
        // The last watering (1.20 L, no runoff) only proves the plant needed
        // at least 1.20 L, but the legacy model averages it as exactly 1.20 L.
        let result = try XCTUnwrap(legacy(WateringHistory.steady(4) + [(1.20, 0.00)]))
        XCTAssertEqual(result.next, 1.3270588235294118, accuracy: accuracy)
    }

    func test_fullRunoffLast_returnsNoRecommendationDespiteHistory() {
        XCTAssertNil(legacy(WateringHistory.steady(4) + [(1.20, 1.20)]))
    }

    func test_highRunoffLast_movesHalfwayTowardNewRetention() throws {
        let result = try XCTUnwrap(legacy(WateringHistory.steady(4) + [(1.20, 0.48)]))
        XCTAssertEqual(result.next, 0.9882352941176471, accuracy: accuracy)
    }

    func test_smallTopUpLast_cutsRecommendationAlmostInHalf() throws {
        // 0.30 L top-up with 0.05 L runoff after four 1.20 L waterings.
        let result = try XCTUnwrap(legacy(WateringHistory.steady(4) + [(0.30, 0.05)]))
        XCTAssertEqual(result.next, 0.6564705882352943, accuracy: accuracy)
    }

    func test_unusuallyLargeWateringLast_nearlyDoublesRecommendation() throws {
        let result = try XCTUnwrap(legacy(WateringHistory.steady(4) + [(3.00, 0.45)]))
        XCTAssertEqual(result.next, 2.28, accuracy: accuracy)
    }

    // MARK: - Changing demand

    func test_risingDemand_lagsBehindLatestRetention() throws {
        let history: [(water: Double, runoff: Double)] = [
            (0.40, 0.06), (0.50, 0.07), (0.70, 0.10), (1.00, 0.15), (1.40, 0.20), (1.90, 0.28)
        ]
        let result = try XCTUnwrap(legacy(history))
        XCTAssertEqual(result.next, 1.4470588235294117, accuracy: accuracy)
        // The latest watering retained 1.62 L, which needs 1.62 / 0.85 = 1.91 L for 15% runoff.
        XCTAssertLessThan(result.next, 1.62 / 0.85)
    }

    func test_decliningDemand_overshootsLatestRetention() throws {
        let history: [(water: Double, runoff: Double)] = [
            (1.90, 0.30), (1.70, 0.30), (1.50, 0.30), (1.30, 0.30), (1.10, 0.30)
        ]
        let result = try XCTUnwrap(legacy(history))
        XCTAssertEqual(result.next, 1.1764705882352942, accuracy: accuracy)
        // The latest watering retained 0.80 L, which needs only 0.94 L.
        XCTAssertGreaterThan(result.next, 0.80 / 0.85)
    }

    func test_longEarlyHistory_keepsPullingRecommendationDown() throws {
        // 30 seedling waterings (0.34 L retained), then three at 1.70 L retained.
        let history = WateringHistory.steady(30, water: 0.40, runoff: 0.06)
            + WateringHistory.steady(3, water: 2.00, runoff: 0.30)
        let result = try XCTUnwrap(legacy(history))
        XCTAssertEqual(result.next, 1.2727272727272727, accuracy: accuracy)
        XCTAssertLessThan(result.next, 1.70 / 0.85)
    }

    func test_irregularIntervals_doNotChangeTheResult() throws {
        let amounts = WateringHistory.steady(3) + [(1.40, 0.25)]
        let regular = LegacyRecommendationModel.recommend(WateringHistory.make(amounts), maxRetentionCapacity: 4.5)
        let irregular = LegacyRecommendationModel.recommend(
            WateringHistory.make(amounts, atHours: [0, 20, 90, 100]),
            maxRetentionCapacity: 4.5
        )
        XCTAssertEqual(try XCTUnwrap(regular).next, try XCTUnwrap(irregular).next, accuracy: accuracy)
    }

    // MARK: - Goal and capacity limits

    func test_goal90Percent_recommendsTenTimesTheRetention() throws {
        let result = try XCTUnwrap(legacy(WateringHistory.steady(4), goal: 90))
        XCTAssertEqual(result.next, 10.2, accuracy: 1e-9)
    }

    func test_goal99_9Percent_exceedsTheLargestLoggableWatering() throws {
        let result = try XCTUnwrap(legacy(WateringHistory.steady(4), goal: 99.9))
        XCTAssertEqual(result.next, 1020.0, accuracy: 1e-6)
        XCTAssertGreaterThan(result.next, AppConstants.waterAddedRange.upperBound)
    }

    func test_expectedRetentionAboveCapacity_isCappedAtCapacity() throws {
        let result = try XCTUnwrap(legacy(WateringHistory.steady(4), mrc: 0.9))
        XCTAssertEqual(result.next, 0.9 / 0.85, accuracy: accuracy)
    }

    // MARK: - History edits and units

    func test_backdatedLog_insertionOrderDoesNotMatter() throws {
        let history = WateringHistory.make([(1.00, 0.15), (1.20, 0.20), (1.10, 0.10)])
        let shuffled = [history[2], history[0], history[1]]
        let a = try XCTUnwrap(LegacyRecommendationModel.recommend(history, maxRetentionCapacity: 4.5))
        let b = try XCTUnwrap(LegacyRecommendationModel.recommend(shuffled, maxRetentionCapacity: 4.5))
        XCTAssertEqual(a.next, b.next, accuracy: accuracy)
    }

    func test_deletedLog_givesSameResultAsNeverLoggingIt() throws {
        let history = WateringHistory.make([(1.00, 0.15), (0.30, 0.05), (1.10, 0.10)])
        let withoutTopUp = [history[0], history[2]]
        let rebuilt = WateringHistory.make([(1.00, 0.15), (1.10, 0.10)])
        let a = try XCTUnwrap(LegacyRecommendationModel.recommend(withoutTopUp, maxRetentionCapacity: 4.5))
        let b = try XCTUnwrap(LegacyRecommendationModel.recommend(rebuilt, maxRetentionCapacity: 4.5))
        XCTAssertEqual(a.next, b.next, accuracy: accuracy)
    }

    func test_historyEnteredInGallons_matchesLiters() throws {
        let liters: [(water: Double, runoff: Double)] = [(1.00, 0.15), (1.20, 0.20), (1.10, 0.10)]
        let viaGallons = liters.map { amount in
            (water: UnitConversionService.toLiters(UnitConversionService.fromLiters(amount.water, to: .gallons), from: .gallons),
             runoff: UnitConversionService.toLiters(UnitConversionService.fromLiters(amount.runoff, to: .gallons), from: .gallons))
        }
        let a = try XCTUnwrap(legacy(liters))
        let b = try XCTUnwrap(legacy(viaGallons))
        XCTAssertEqual(a.next, b.next, accuracy: 1e-12)
    }
}

/// Confirms the test-target copy above reproduces the production code exactly,
/// so the characterization tests describe what users actually saw.
@MainActor
final class LegacyNextAlgorithmParityTests: XCTestCase {

    private func production(_ history: [TestWatering], mrc: Double, goal: Double) -> NextWaterRecommendation? {
        let logs = history.map {
            WateringLog(waterAdded: $0.water, runoffCollected: $0.runoff, dateTime: $0.date)
        }
        let newestFirst = logs.sorted { $0.dateTime > $1.dateTime }
        guard let last = newestFirst.first else { return nil }
        let average = newestFirst.map(\.retained).reduce(0, +) / Double(newestFirst.count)
        return WateringCalculationService.computeNextWaterRecommendation(
            lastLog: last,
            averageRetained: average,
            maxRetentionCapacity: mrc,
            goalRunoffPercent: goal
        )
    }

    func test_copyMatchesProduction_forRepresentativeHistories() {
        let histories: [[(water: Double, runoff: Double)]] = [
            [(1.20, 0.18)],
            WateringHistory.steady(4) + [(1.20, 0.00)],
            WateringHistory.steady(4) + [(1.20, 1.20)],
            WateringHistory.steady(4) + [(0.30, 0.05)],
            [(0.40, 0.06), (0.50, 0.07), (0.70, 0.10), (1.00, 0.15), (1.40, 0.20), (1.90, 0.28)]
        ]
        for (index, amounts) in histories.enumerated() {
            for (mrc, goal) in [(4.5, 15.0), (0.9, 15.0), (4.5, 30.0)] {
                let history = WateringHistory.make(amounts)
                let copy = LegacyRecommendationModel.recommend(history, maxRetentionCapacity: mrc, goalRunoffPercent: goal)
                let real = production(history, mrc: mrc, goal: goal)
                let label = "history \(index), mrc \(mrc), goal \(goal)"
                switch (copy, real) {
                case (nil, nil):
                    break
                case let (copy?, real?):
                    XCTAssertEqual(copy.next, real.next, accuracy: 1e-12, label)
                    XCTAssertEqual(copy.goalRunoff, real.goalRunoff, accuracy: 1e-12, label)
                default:
                    XCTFail("copy and production disagree on whether to recommend: \(label)")
                }
            }
        }
    }
}
