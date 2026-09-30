// © 2026 Evapotrack. All rights reserved.
// RecommendationEngineTests.swift
// EvapotrackDevTests
//
// Tests for RecommendationEngine built from real watering histories.
// Expected values come from the reference implementation used to select the
// model (see the engineering report), not from hand-picked inputs.

import XCTest
@testable import EvapotrackDev

final class RecommendationEngineTests: XCTestCase {

    private let accuracy = 1e-9
    private struct NoRecommendation: Error {}

    // MARK: - Helpers

    private func outcome(
        _ amounts: [(water: Double, runoff: Double)],
        mrc: Double = 4.5,
        goal: Double = 15.0
    ) -> RecommendationOutcome {
        RecommendationEngine.recommend(
            observations: WateringHistory.make(amounts).map(\.observation),
            maxRetentionCapacity: mrc,
            goalRunoffPercent: goal
        )
    }

    private func recommendation(
        _ amounts: [(water: Double, runoff: Double)],
        mrc: Double = 4.5,
        goal: Double = 15.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Recommendation {
        guard case .recommendation(let result) = outcome(amounts, mrc: mrc, goal: goal) else {
            XCTFail("expected a recommendation", file: file, line: line)
            throw NoRecommendation()
        }
        return result
    }

    private var steadyFour: [(water: Double, runoff: Double)] { WateringHistory.steady(4) }

    // MARK: - No usable history

    func test_noHistory_saysSo() {
        XCTAssertEqual(outcome([]), .noHistory)
    }

    func test_everyWateringDrainedCompletely_hasNoUsableData() {
        XCTAssertEqual(outcome([(1.00, 1.00), (0.80, 0.80)]), .noUsableData)
    }

    // MARK: - Basic histories

    func test_oneWatering_recommendsSameAmountAgain() throws {
        // 1.20 L in, 0.18 L out -> 1.02 L retained -> 1.02 / 0.85 = 1.20 L
        let result = try recommendation([(1.20, 0.18)])
        XCTAssertEqual(result.nextWater, 1.20, accuracy: accuracy)
        XCTAssertEqual(result.goalRunoff, 0.18, accuracy: accuracy)
        XCTAssertEqual(result.estimatedRetention, 1.02, accuracy: accuracy)
        XCTAssertEqual(result.goalRunoffPercent, 15.0)
        XCTAssertEqual(result.basis, .measured(wateringsWithRunoff: 1))
        XCTAssertEqual(result.notes, [])
    }

    func test_steadyHistory_isAFixedPoint() throws {
        let result = try recommendation(WateringHistory.steady(5))
        XCTAssertEqual(result.nextWater, 1.20, accuracy: accuracy)
        XCTAssertEqual(result.basis, .measured(wateringsWithRunoff: 5))
        XCTAssertEqual(result.notes, [])
    }

    func test_multipleWaterings_weightRecentWateringsMost() throws {
        let result = try recommendation([(1.00, 0.15), (1.20, 0.20), (1.10, 0.10)])
        XCTAssertEqual(result.nextWater, 1.1566352941176472, accuracy: accuracy)
        XCTAssertEqual(result.estimatedRetention, 0.98314, accuracy: accuracy)
    }

    // MARK: - Zero runoff (censored observations)

    func test_onlyNoRunoffWaterings_useTheWaterAddedAsALowerBound() throws {
        let result = try recommendation([(0.60, 0.00)])
        XCTAssertEqual(result.basis, .noRunoffYet)
        XCTAssertEqual(result.estimatedRetention, 0.60, accuracy: accuracy)
        XCTAssertEqual(result.nextWater, 0.7058823529411765, accuracy: accuracy)
        XCTAssertEqual(result.notes, [.lastWateringNoRunoff(waterAdded: 0.60, raisedEstimate: true)])
    }

    func test_noRunoffAtUsualAmount_raisesNext() throws {
        // Four 1.20 L waterings retained 1.02 L; the fifth (1.20 L) produced no
        // runoff, so the plant needed at least 1.20 L.
        let result = try recommendation(steadyFour + [(1.20, 0.00)])
        XCTAssertEqual(result.estimatedRetention, 1.20, accuracy: accuracy)
        XCTAssertEqual(result.nextWater, 1.20 / 0.85, accuracy: accuracy)
        XCTAssertEqual(result.notes, [.lastWateringNoRunoff(waterAdded: 1.20, raisedEstimate: true)])
    }

    func test_noRunoffAboveUsualAmount_raisesNextToAtLeastThatAmount() throws {
        let result = try recommendation(steadyFour + [(1.30, 0.00)])
        XCTAssertEqual(result.nextWater, 1.5294117647058825, accuracy: accuracy)
        XCTAssertEqual(result.notes, [.lastWateringNoRunoff(waterAdded: 1.30, raisedEstimate: true)])
    }

    func test_smallNoRunoffTopUp_doesNotLowerNext() throws {
        // 0.30 L sip with no runoff says only "at least 0.30 L": no new information.
        let result = try recommendation(steadyFour + [(0.30, 0.00)])
        XCTAssertEqual(result.nextWater, 1.20, accuracy: accuracy)
        XCTAssertEqual(result.notes, [.lastWateringNoRunoff(waterAdded: 0.30, raisedEstimate: false)])
    }

    func test_firstMeasurementReplacesEarlierLowerBound() throws {
        // A no-runoff watering (0.60 L) followed by a measured one (1.20 L retained).
        let result = try recommendation([(0.60, 0.00), (1.40, 0.20)])
        XCTAssertEqual(result.estimatedRetention, 1.20, accuracy: accuracy)
        XCTAssertEqual(result.nextWater, 1.20 / 0.85, accuracy: accuracy)
        XCTAssertEqual(result.basis, .measured(wateringsWithRunoff: 1))
    }

    func test_risingNoRunoffWaterings_raiseNextOnlyToWhatWasProven() throws {
        // 1.0 → 1.4 L, never any runoff: the plant needed at least 1.4 L. Next is
        // that proven minimum sized for the goal, not an extrapolated trend.
        let result = try recommendation([(1.0, 0), (1.1, 0), (1.2, 0), (1.3, 0), (1.4, 0)])
        XCTAssertEqual(result.basis, .noRunoffYet)
        XCTAssertEqual(result.estimatedRetention, 1.4, accuracy: accuracy)
        XCTAssertEqual(result.nextWater, 1.4 / 0.85, accuracy: accuracy)
        XCTAssertEqual(result.notes, [.lastWateringNoRunoff(waterAdded: 1.4, raisedEstimate: true)])
    }

    func test_followingNextWithoutEverGettingRunoff_stopsAtCapacity() throws {
        // A grower who follows Next and still never sees runoff: each watering
        // raises Next, but never past what the capacity allows, and the capacity
        // note tells them the capacity itself may be too low.
        var amounts: [(water: Double, runoff: Double)] = [(1.0, 0)]
        var result = try recommendation(amounts, mrc: 1.5)
        for _ in 0..<9 {
            let previous = result.nextWater
            amounts.append((result.nextWater, 0))
            result = try recommendation(amounts, mrc: 1.5)
            XCTAssertGreaterThanOrEqual(result.nextWater, previous - accuracy)
            XCTAssertLessThanOrEqual(result.nextWater, 1.5 / 0.85 + accuracy)
        }
        XCTAssertEqual(result.nextWater, 1.5 / 0.85, accuracy: accuracy)
        XCTAssertTrue(result.notes.contains(.limitedByCapacity(capacity: 1.5)))
    }

    // MARK: - Full runoff

    func test_fullRunoffLast_isSkippedAndEarlierWateringsAreUsed() throws {
        let result = try recommendation(steadyFour + [(1.20, 1.20)])
        XCTAssertEqual(result.nextWater, 1.20, accuracy: accuracy)
        XCTAssertEqual(result.basis, .measured(wateringsWithRunoff: 4))
        XCTAssertEqual(result.notes, [.lastWateringFullRunoff])
    }

    func test_severalFullRunoffsInARow_keepTheEarlierEstimate() throws {
        let result = try recommendation(steadyFour + [(1.20, 1.20), (1.20, 1.20), (1.20, 1.20)])
        XCTAssertEqual(result.nextWater, 1.20, accuracy: accuracy)
        XCTAssertEqual(result.estimatedRetention, 1.02, accuracy: accuracy)
        XCTAssertEqual(result.basis, .measured(wateringsWithRunoff: 4))
        XCTAssertEqual(result.notes, [.lastWateringFullRunoff])
    }

    // MARK: - Outliers

    func test_highRunoffLast_lowersNextByAtMostAQuarterOfTheForecast() throws {
        // Retained 0.72 L against a 1.02 L forecast; the drop is limited to 25%.
        let result = try recommendation(steadyFour + [(1.20, 0.48)])
        XCTAssertEqual(result.nextWater, 1.0260000000000002, accuracy: accuracy)
        XCTAssertEqual(result.estimatedRetention, 0.8721000000000001, accuracy: accuracy)
    }

    func test_smallTopUpWithRunoff_cannotDragNextDown() throws {
        // 0.30 L with 0.05 L runoff after 1.20 L waterings: treated like any
        // low reading, limited to a 25% drop. The legacy model gave 0.66 L.
        let result = try recommendation(steadyFour + [(0.30, 0.05)])
        XCTAssertEqual(result.nextWater, 1.0260000000000002, accuracy: accuracy)
        XCTAssertGreaterThan(result.nextWater, 0.6564705882352943)
    }

    func test_unusuallyLargeWatering_isFollowed() throws {
        // A 3.00 L watering that retained 2.55 L is real demand (e.g. after a long gap).
        let result = try recommendation(steadyFour + [(3.00, 0.45)])
        XCTAssertEqual(result.nextWater, 2.244, accuracy: accuracy)
        XCTAssertEqual(result.notes, [.demandRising])
    }

    // MARK: - Changing demand

    func test_risingDemand_tracksTheGrowingPlant() throws {
        let history: [(water: Double, runoff: Double)] = [
            (0.40, 0.06), (0.50, 0.07), (0.70, 0.10), (1.00, 0.15), (1.40, 0.20), (1.90, 0.28)
        ]
        let result = try recommendation(history)
        XCTAssertEqual(result.nextWater, 1.6870408922729412, accuracy: accuracy)
        XCTAssertEqual(result.notes, [.demandRising])
        // Closer to the 1.91 L the latest watering implies than the legacy 1.45 L.
        let legacy = try XCTUnwrap(LegacyRecommendationModel.recommend(WateringHistory.make(history), maxRetentionCapacity: 4.5))
        XCTAssertLessThan(abs(result.nextWater - 1.62 / 0.85), abs(legacy.next - 1.62 / 0.85))
    }

    func test_decliningDemand_followsThePlantDown() throws {
        let history: [(water: Double, runoff: Double)] = [
            (1.90, 0.30), (1.70, 0.30), (1.50, 0.30), (1.30, 0.30), (1.10, 0.30)
        ]
        let result = try recommendation(history)
        XCTAssertEqual(result.nextWater, 1.056957374117647, accuracy: accuracy)
        XCTAssertEqual(result.notes, [.demandFalling])
        let legacy = try XCTUnwrap(LegacyRecommendationModel.recommend(WateringHistory.make(history), maxRetentionCapacity: 4.5))
        XCTAssertLessThan(result.nextWater, legacy.next)
    }

    func test_longEarlyHistory_doesNotHoldNextBack() throws {
        let history = WateringHistory.steady(30, water: 0.40, runoff: 0.06)
            + WateringHistory.steady(3, water: 2.00, runoff: 0.30)
        let result = try recommendation(history)
        XCTAssertEqual(result.nextWater, 2.0493952, accuracy: accuracy)
        XCTAssertGreaterThan(result.nextWater, 1.70 / 0.85)
    }

    // MARK: - Goal, capacity and input limits

    func test_goalAbove50Percent_isLimitedTo50() throws {
        for requested in [90.0, 99.9] {
            let result = try recommendation(steadyFour, goal: requested)
            XCTAssertEqual(result.goalRunoffPercent, 50.0)
            XCTAssertEqual(result.nextWater, 2.04, accuracy: accuracy)
            XCTAssertEqual(result.notes, [.goalAdjusted(requestedPercent: requested)])
        }
    }

    func test_goalBelow5Percent_isRaisedTo5() throws {
        let result = try recommendation(steadyFour, goal: 2.0)
        XCTAssertEqual(result.goalRunoffPercent, 5.0)
        XCTAssertEqual(result.nextWater, 1.0736842105263158, accuracy: accuracy)
        XCTAssertEqual(result.notes, [.goalAdjusted(requestedPercent: 2.0)])
    }

    func test_goalNotANumber_usesTheDefaultGoal() throws {
        let result = try recommendation(steadyFour, goal: .nan)
        XCTAssertEqual(result.goalRunoffPercent, AppConstants.targetRunoffPercent)
        XCTAssertEqual(result.nextWater, 1.20, accuracy: accuracy)
        guard case .goalAdjusted(let requested)? = result.notes.first else {
            return XCTFail("expected a goalAdjusted note")
        }
        XCTAssertTrue(requested.isNaN)
    }

    func test_estimateAboveCapacity_isLimitedToCapacity() throws {
        let result = try recommendation(steadyFour, mrc: 0.9)
        XCTAssertEqual(result.estimatedRetention, 0.9, accuracy: accuracy)
        XCTAssertEqual(result.nextWater, 0.9 / 0.85, accuracy: accuracy)
        XCTAssertEqual(result.notes, [.limitedByCapacity(capacity: 0.9)])
    }

    func test_editingCapacity_onlyMattersWhenItIsTheLimit() throws {
        // Same logs, capacity edited from 1.5 L to 2.0 L: the estimate (1.02 L)
        // is below both, so Next is unchanged. Lowering it to 0.9 L caps Next.
        for capacity in [1.5, 2.0] {
            let result = try recommendation(steadyFour, mrc: capacity)
            XCTAssertEqual(result.nextWater, 1.20, accuracy: accuracy, "capacity \(capacity)")
            XCTAssertEqual(result.notes, [], "capacity \(capacity)")
        }
        let capped = try recommendation(steadyFour, mrc: 0.9)
        XCTAssertEqual(capped.nextWater, 0.9 / 0.85, accuracy: accuracy)
        XCTAssertEqual(capped.notes, [.limitedByCapacity(capacity: 0.9)])
    }

    func test_nextNeverExceedsTheLargestLoggableWatering() throws {
        let result = try recommendation([(95.0, 5.0)], mrc: 100, goal: 50)
        XCTAssertEqual(result.nextWater, AppConstants.waterAddedRange.upperBound)
        XCTAssertEqual(result.goalRunoff, 50.0, accuracy: accuracy)
        XCTAssertEqual(result.notes, [.limitedByMaximumWater(maximum: AppConstants.waterAddedRange.upperBound)])
    }

    func test_invalidObservations_areIgnored() throws {
        let result = try recommendation([(1.20, 0.18), (.nan, 0.0), (1.00, -0.10), (.infinity, 0.2)])
        XCTAssertEqual(result.nextWater, 1.20, accuracy: accuracy)
        XCTAssertEqual(result.basis, .measured(wateringsWithRunoff: 1))
        XCTAssertEqual(result.notes, [])
    }

    // MARK: - History edits, ordering and units

    func test_backdatedLog_insertionOrderDoesNotMatter() {
        let history = WateringHistory.make([(1.00, 0.15), (1.20, 0.20), (0.30, 0.00), (1.10, 0.10)])
        let shuffled = [history[3], history[0], history[2], history[1]]
        let a = RecommendationEngine.recommend(observations: history.map(\.observation), maxRetentionCapacity: 4.5, goalRunoffPercent: 15)
        let b = RecommendationEngine.recommend(observations: shuffled.map(\.observation), maxRetentionCapacity: 4.5, goalRunoffPercent: 15)
        XCTAssertEqual(a, b)
    }

    func test_deletedLog_givesSameResultAsNeverLoggingIt() {
        let history = WateringHistory.make([(1.00, 0.15), (0.30, 0.05), (1.10, 0.10), (1.25, 0.20)])
        let afterDelete = [history[0], history[2], history[3]]
        let neverLogged = WateringHistory.make([(1.00, 0.15), (1.10, 0.10), (1.25, 0.20)])
        let a = RecommendationEngine.recommend(observations: afterDelete.map(\.observation), maxRetentionCapacity: 4.5, goalRunoffPercent: 15)
        let b = RecommendationEngine.recommend(observations: neverLogged.map(\.observation), maxRetentionCapacity: 4.5, goalRunoffPercent: 15)
        XCTAssertEqual(a, b)
    }

    func test_irregularIntervals_onlyOrderMatters() {
        let amounts: [(water: Double, runoff: Double)] = [(1.00, 0.15), (1.20, 0.20), (1.40, 0.25), (1.10, 0.10)]
        let regular = WateringHistory.make(amounts)
        let irregular = WateringHistory.make(amounts, atHours: [0, 18, 90, 101])
        let a = RecommendationEngine.recommend(observations: regular.map(\.observation), maxRetentionCapacity: 4.5, goalRunoffPercent: 15)
        let b = RecommendationEngine.recommend(observations: irregular.map(\.observation), maxRetentionCapacity: 4.5, goalRunoffPercent: 15)
        XCTAssertEqual(a, b)
    }

    func test_sameDate_keepsInputOrder() throws {
        let date = WateringHistory.start
        let observations = [
            WateringObservation(waterAdded: 1.20, runoff: 0.18, date: date),
            WateringObservation(waterAdded: 1.20, runoff: 0.00, date: date)
        ]
        guard case .recommendation(let result) = RecommendationEngine.recommend(
            observations: observations, maxRetentionCapacity: 4.5, goalRunoffPercent: 15
        ) else {
            return XCTFail("expected a recommendation")
        }
        XCTAssertEqual(result.notes.first, .lastWateringNoRunoff(waterAdded: 1.20, raisedEstimate: true))
    }

    func test_unitIndependence_scalingEveryVolumeScalesNext() throws {
        // Logging the same plant in gallons stores the same liters; any common
        // scale factor must carry straight through to Next.
        let history: [(water: Double, runoff: Double)] = [
            (0.40, 0.06), (0.50, 0.07), (0.70, 0.10), (1.00, 0.15), (1.40, 0.20), (1.90, 0.28)
        ]
        let factor = 3.785411784
        let scaled = history.map { (water: $0.water * factor, runoff: $0.runoff * factor) }
        let base = try recommendation(history, mrc: 4.5)
        let big = try recommendation(scaled, mrc: 4.5 * factor)
        XCTAssertEqual(big.nextWater, base.nextWater * factor, accuracy: 1e-9)
        XCTAssertEqual(big.notes, base.notes)
    }

    func test_matchesLegacyForTheCommonCases() throws {
        // First watering and a steady history give the same Next as before.
        let legacyOne = try XCTUnwrap(LegacyRecommendationModel.recommend(WateringHistory.make([(1.20, 0.18)]), maxRetentionCapacity: 4.5))
        let legacySteady = try XCTUnwrap(LegacyRecommendationModel.recommend(WateringHistory.make(WateringHistory.steady(6)), maxRetentionCapacity: 4.5))
        XCTAssertEqual(try recommendation([(1.20, 0.18)]).nextWater, legacyOne.next, accuracy: accuracy)
        XCTAssertEqual(try recommendation(WateringHistory.steady(6)).nextWater, legacySteady.next, accuracy: accuracy)
    }

    // MARK: - Safety bounds (fuzz)

    func test_randomHistories_alwaysGiveSafeValues() {
        var generator = SplitMix64(seed: 20260927)
        for _ in 0..<2_000 {
            let count = Int.random(in: 1...40, using: &generator)
            var observations: [WateringObservation] = []
            for index in 0..<count {
                let water = Double.random(in: 0.001...100, using: &generator)
                let runoffShare = [0.0, 1.0, Double.random(in: 0...1, using: &generator)].randomElement(using: &generator) ?? 0
                observations.append(WateringObservation(
                    waterAdded: water,
                    runoff: water * runoffShare,
                    date: WateringHistory.start.addingTimeInterval(Double(index) * 3600)
                ))
            }
            let mrc = Double.random(in: 0.001...100, using: &generator)
            let goal = Double.random(in: -10...120, using: &generator)
            switch RecommendationEngine.recommend(observations: observations, maxRetentionCapacity: mrc, goalRunoffPercent: goal) {
            case .recommendation(let result):
                XCTAssertTrue(result.nextWater.isFinite)
                XCTAssertGreaterThan(result.nextWater, 0)
                XCTAssertLessThanOrEqual(result.nextWater, AppConstants.waterAddedRange.upperBound)
                XCTAssertTrue(AppConstants.goalRunoffPercentRange.contains(result.goalRunoffPercent))
                XCTAssertLessThanOrEqual(result.estimatedRetention, mrc + 1e-12)
                XCTAssertGreaterThan(result.estimatedRetention, 0)
                XCTAssertEqual(result.goalRunoff, result.nextWater * result.goalRunoffPercent / 100, accuracy: 1e-9)
            case .noUsableData:
                XCTAssertTrue(observations.allSatisfy { $0.runoff >= $0.waterAdded })
            case .noHistory:
                XCTFail("history was not empty")
            }
        }
    }
}

/// Small deterministic generator so fuzz and simulation tests are repeatable.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
