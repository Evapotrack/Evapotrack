// InsightsAlgorithmTests.swift
// EvapotrackDevTests
//
// Tests for WateringCalculationService.computeNextWaterRecommendation().
// Validates the Insights algorithm:
//   expectedRetained = (retained_last + averageRetained) / 2
//   next = expectedRetained / (1 - goalRunoffPercent / 100), capped by maxRetentionCapacity
//   goalRunoff = next × (goalRunoffPercent / 100)
// All expected values are hand-computed from the algorithm.

import XCTest
@testable import EvapotrackDev

final class InsightsAlgorithmTests: XCTestCase {

    private let accuracy = 0.001

    /// Helper to create a WateringLog with specific water/runoff values.
    private func makeLog(waterAdded: Double, runoffCollected: Double) -> WateringLog {
        WateringLog(waterAdded: waterAdded, runoffCollected: runoffCollected, dateTime: Date())
    }

    // MARK: - Normal Cases

    func test_nextWater_normalCase_targetRunoff() {
        // retained=0.85, avgRetained=0.6
        // expectedRetained=(0.85+0.6)/2=0.725
        // next=0.725/0.85=0.8529
        let log = makeLog(waterAdded: 1.0, runoffCollected: 0.15)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 0.6, maxRetentionCapacity: 2.0
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.next, 0.8529, accuracy: accuracy)
        XCTAssertEqual(result!.goalRunoff, result!.next * 0.15, accuracy: accuracy)
    }

    func test_nextWater_highRunoff_reducesRecommendation() {
        // retained=0.5, avgRetained=0.5
        // expectedRetained=(0.5+0.5)/2=0.5
        // next=0.5/0.85=0.5882
        let log = makeLog(waterAdded: 1.0, runoffCollected: 0.50)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 0.5, maxRetentionCapacity: 2.0
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.next, 0.5882, accuracy: accuracy)
        XCTAssertEqual(result!.goalRunoff, result!.next * 0.15, accuracy: accuracy)
    }

    func test_nextWater_lowRunoff_increasesRecommendation() {
        // retained=0.95, avgRetained=0.5
        // expectedRetained=(0.95+0.5)/2=0.725
        // next=0.725/0.85=0.8529
        let log = makeLog(waterAdded: 1.0, runoffCollected: 0.05)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 0.5, maxRetentionCapacity: 2.0
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.next, 0.8529, accuracy: accuracy)
        XCTAssertEqual(result!.goalRunoff, result!.next * 0.15, accuracy: accuracy)
    }

    func test_nextWater_nearZeroRunoff() {
        // retained=0.9999, avgRetained=0.5
        // expectedRetained=(0.9999+0.5)/2=0.74995
        // next=0.74995/0.85=0.8823
        let log = makeLog(waterAdded: 1.0, runoffCollected: 0.0001)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 0.5, maxRetentionCapacity: 2.0
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.next, 0.8823, accuracy: accuracy)
        XCTAssertEqual(result!.goalRunoff, result!.next * 0.15, accuracy: accuracy)
    }

    // MARK: - Algorithm Convergence

    func test_nextWater_lowAverage_pullsNextDown() {
        // retained=0.4, avgRetained=0.1
        // expectedRetained=(0.4+0.1)/2=0.25
        // next=0.25/0.85=0.2941
        let log = makeLog(waterAdded: 0.5, runoffCollected: 0.1)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 0.1, maxRetentionCapacity: 2.0
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.next, 0.2941, accuracy: accuracy)
        XCTAssertEqual(result!.goalRunoff, result!.next * 0.15, accuracy: accuracy)
    }

    func test_nextWater_highAverage_cappedByCapacity() {
        // retained=0.5, avgRetained=1.5, maxRetCap=0.8
        // expectedRetained=(0.5+1.5)/2=1.0
        // uncapped next=1.0/0.85=1.1765
        // maxSafe=0.8/0.85=0.9412
        // next=min(1.1765, 0.9412)=0.9412 (capped)
        let log = makeLog(waterAdded: 1.0, runoffCollected: 0.5)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 1.5, maxRetentionCapacity: 0.8
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.next, 0.9412, accuracy: accuracy)
        XCTAssertEqual(result!.goalRunoff, result!.next * 0.15, accuracy: accuracy)
    }

    // MARK: - Nil Returns (retained_last <= 0)

    func test_nextWater_retainedLastZero_returnsNil() {
        let log = makeLog(waterAdded: 1.0, runoffCollected: 1.0)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 0.5, maxRetentionCapacity: 2.0
        )
        XCTAssertNil(result)
    }

    func test_nextWater_retainedLastZero_equalInputs_returnsNil() {
        let log = makeLog(waterAdded: 0.5, runoffCollected: 0.5)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 0.3, maxRetentionCapacity: 1.0
        )
        XCTAssertNil(result)
    }

    // MARK: - GoalRunoff Relationship

    func test_nextWater_goalRunoff_isAlwaysGoalPercentOfNext() {
        let log = makeLog(waterAdded: 1.0, runoffCollected: 0.15)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 0.6, maxRetentionCapacity: 2.0
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.goalRunoff, result!.next * 0.15, accuracy: accuracy)
    }

    func test_nextWater_customGoalRunoffPercent() {
        // retained=0.85, avgRetained=0.6, goal=20%
        // expectedRetained=(0.85+0.6)/2=0.725
        // next=0.725/0.80=0.9063
        let log = makeLog(waterAdded: 1.0, runoffCollected: 0.15)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 0.6, maxRetentionCapacity: 2.0,
            goalRunoffPercent: 20.0
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.next, 0.9063, accuracy: accuracy)
        XCTAssertEqual(result!.goalRunoff, result!.next * 0.20, accuracy: accuracy)
    }

    // MARK: - Edge Cases

    func test_nextWater_veryHighRunoff_smallRecommendation() {
        // retained=0.1, avgRetained=0.05
        // expectedRetained=(0.1+0.05)/2=0.075
        // next=0.075/0.85=0.0882
        let log = makeLog(waterAdded: 1.0, runoffCollected: 0.9)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 0.05, maxRetentionCapacity: 2.0
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.next, 0.0882, accuracy: accuracy)
        XCTAssertEqual(result!.goalRunoff, result!.next * 0.15, accuracy: accuracy)
    }

    func test_nextWater_exactTargetRunoff_stableRecommendation() {
        // retained=0.85, avgRetained=0.85 (stable medium)
        // expectedRetained=(0.85+0.85)/2=0.85
        // next=0.85/0.85=1.0
        let log = makeLog(waterAdded: 1.0, runoffCollected: 0.15)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 0.85, maxRetentionCapacity: 2.0
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.next, 1.0, accuracy: accuracy)
        XCTAssertEqual(result!.goalRunoff, 0.15, accuracy: accuracy)
    }

    func test_nextWater_smallValues_precision() {
        // retained=0.09, avgRetained=0.05
        // expectedRetained=(0.09+0.05)/2=0.07
        // next=0.07/0.85=0.08235
        let log = makeLog(waterAdded: 0.1, runoffCollected: 0.01)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 0.05, maxRetentionCapacity: 0.5
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.next, 0.08235, accuracy: accuracy)
        XCTAssertEqual(result!.goalRunoff, result!.next * 0.15, accuracy: accuracy)
    }

    func test_nextWater_lowAverage_pullsNextBelowRetained() {
        // retained=0.85, avgRetained=0.1
        // expectedRetained=(0.85+0.1)/2=0.475
        // next=0.475/0.85=0.5588
        let log = makeLog(waterAdded: 1.0, runoffCollected: 0.15)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 0.1, maxRetentionCapacity: 0.85
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.next, 0.5588, accuracy: accuracy)
        XCTAssertEqual(result!.goalRunoff, result!.next * 0.15, accuracy: accuracy)
    }

    func test_nextWater_largeValues_unclamped() {
        // retained=1.5, avgRetained=1.5
        // expectedRetained=(1.5+1.5)/2=1.5
        // next=1.5/0.85=1.7647
        // maxSafe=2.0/0.85=2.3529
        // next=1.7647 (under cap)
        let log = makeLog(waterAdded: 3.0, runoffCollected: 1.5)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 1.5, maxRetentionCapacity: 2.0
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.next, 1.7647, accuracy: accuracy)
        XCTAssertEqual(result!.goalRunoff, result!.next * 0.15, accuracy: accuracy)
    }

    // MARK: - Capacity Cap

    func test_nextWater_cappedByMaxRetentionCapacity() {
        // retained=1.0, avgRetained=1.0, maxRetCap=0.5
        // expectedRetained=(1.0+1.0)/2=1.0
        // uncapped next=1.0/0.85=1.1765
        // maxSafe=0.5/0.85=0.5882
        // next=0.5882 (capped)
        let log = makeLog(waterAdded: 2.0, runoffCollected: 1.0)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 1.0, maxRetentionCapacity: 0.5
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.next, 0.5882, accuracy: accuracy)
        XCTAssertEqual(result!.goalRunoff, result!.next * 0.15, accuracy: accuracy)
    }

    func test_nextWater_notCappedWhenBelowMax() {
        // retained=0.3, avgRetained=0.3, maxRetCap=2.0
        // expectedRetained=0.3
        // next=0.3/0.85=0.3529
        // maxSafe=2.0/0.85=2.3529
        // not capped
        let log = makeLog(waterAdded: 0.5, runoffCollected: 0.2)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 0.3, maxRetentionCapacity: 2.0
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.next, 0.3529, accuracy: accuracy)
    }

    // MARK: - GoalRunoffPercent Stored

    func test_nextWater_goalRunoffPercent_storedInResult() {
        let log = makeLog(waterAdded: 1.0, runoffCollected: 0.15)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 0.6, maxRetentionCapacity: 2.0
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.goalRunoffPercent, 15.0, accuracy: accuracy)
    }

    func test_nextWater_customGoalRunoffPercent_storedInResult() {
        let log = makeLog(waterAdded: 1.0, runoffCollected: 0.15)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: 0.6, maxRetentionCapacity: 2.0,
            goalRunoffPercent: 20.0
        )
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.goalRunoffPercent, 20.0, accuracy: accuracy)
    }

    // MARK: - Mathematical Soundness

    func test_nextWater_producesExactGoalRunoff_whenAbsorptionMatchesEstimate() {
        // If the medium absorbs expectedRetained, applying next should produce
        // exactly goalRunoffPercent runoff.
        let retainedLast = 0.85
        let avgRetained = 0.75
        let goal = 15.0

        let log = makeLog(waterAdded: 1.0, runoffCollected: 1.0 - retainedLast)
        let result = WateringCalculationService.computeNextWaterRecommendation(
            lastLog: log, averageRetained: avgRetained, maxRetentionCapacity: 2.0,
            goalRunoffPercent: goal
        )
        XCTAssertNotNil(result)

        let expectedRetained = (retainedLast + avgRetained) / 2.0
        let simulatedRunoff = result!.next - expectedRetained
        let simulatedRunoffPercent = (simulatedRunoff / result!.next) * 100.0

        XCTAssertEqual(simulatedRunoffPercent, goal, accuracy: accuracy)
    }
}
