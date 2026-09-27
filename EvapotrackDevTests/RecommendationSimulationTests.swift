// © 2026 Evapotrack. All rights reserved.
// RecommendationSimulationTests.swift
// EvapotrackDevTests
//
// Closed-loop checks: a simulated grower waters exactly the recommended
// amount, the plant retains up to its current demand, and anything beyond
// that drains as runoff. These deterministic scenarios reproduce the key
// results of the model-selection study so a regression shows up here.

import XCTest
@testable import EvapotrackDev

final class RecommendationSimulationTests: XCTestCase {

    /// Runs the loop and returns the runoff share (runoff / water) of each watering.
    private func simulate(
        demand: [Double],
        firstWater: Double,
        recommend: ([TestWatering]) -> Double?
    ) -> [Double] {
        var history: [TestWatering] = []
        var water = firstWater
        var runoffShares: [Double] = []
        for (index, need) in demand.enumerated() {
            let runoff = max(0, water - need)
            history.append(TestWatering(
                water: water,
                runoff: runoff,
                date: WateringHistory.start.addingTimeInterval(Double(index) * 48 * 3600)
            ))
            runoffShares.append(runoff / water)
            if let next = recommend(history) { water = next }
        }
        return runoffShares
    }

    private func engine(_ history: [TestWatering]) -> Double? {
        guard case .recommendation(let result) = RecommendationEngine.recommend(
            observations: history.map(\.observation),
            maxRetentionCapacity: 1_000,
            goalRunoffPercent: 15
        ) else { return nil }
        return result.nextWater
    }

    private func legacy(_ history: [TestWatering]) -> Double? {
        LegacyRecommendationModel.recommend(history, maxRetentionCapacity: 1_000, goalRunoffPercent: 15)?.next
    }

    func test_constantDemand_startingAtHalfTheNeed_reachesGoalRunoffBySeventhWatering() {
        let demand = Array(repeating: 1.2, count: 12)
        let engineShares = simulate(demand: demand, firstWater: 0.6, recommend: engine)
        let legacyShares = simulate(demand: demand, firstWater: 0.6, recommend: legacy)

        // No-runoff waterings raise Next ~18% each time until runoff appears,
        // then the first measurement lands exactly on the goal.
        for index in 6..<demand.count {
            XCTAssertEqual(engineShares[index], 0.15, accuracy: 1e-9, "watering \(index + 1)")
        }
        // The legacy model is still far below the goal after twelve waterings.
        XCTAssertLessThan(legacyShares[11], 0.10)
    }

    func test_demandGrowing6PercentPerWatering_alwaysProducesRunoff() {
        let demand = (0..<30).map { 0.6 * pow(1.06, Double($0)) }
        let engineShares = simulate(demand: demand, firstWater: 0.6 / 0.85, recommend: engine)
        let legacyShares = simulate(demand: demand, firstWater: 0.6 / 0.85, recommend: legacy)

        XCTAssertEqual(engineShares.filter { $0 == 0 }.count, 0)
        for share in engineShares.dropFirst(5) {
            XCTAssertGreaterThan(share, 0.05)
            XCTAssertLessThanOrEqual(share, 0.15 + 1e-9)
        }
        // The legacy model spends most of the grow with no runoff at all.
        XCTAssertGreaterThanOrEqual(legacyShares.filter { $0 == 0 }.count, 15)
    }

    func test_sudden35PercentDrop_recoversWithinFourWaterings() {
        let demand = Array(repeating: 1.2, count: 10) + Array(repeating: 0.78, count: 15)
        let engineShares = simulate(demand: demand, firstWater: 1.2 / 0.85, recommend: engine)
        let legacyShares = simulate(demand: demand, firstWater: 1.2 / 0.85, recommend: legacy)

        for index in 13..<demand.count {
            XCTAssertTrue((0.10...0.20).contains(engineShares[index]), "watering \(index + 1): \(engineShares[index])")
        }
        // Fifteen waterings after the drop, the legacy model still overwaters.
        XCTAssertGreaterThan(legacyShares[24], 0.20)
    }
}
