// © 2026 Evapotrack. All rights reserved.
// WateringHistory.swift
// EvapotrackDevTests
//
// Builders for realistic watering histories used by the recommendation tests.
// Every fixture is a list of measured waterings (water added, runoff collected)
// with real dates, so expected values always come from an actual history.

import Foundation

/// One watering as a grower would log it. Volumes are liters.
struct TestWatering: Equatable {
    let water: Double
    let runoff: Double
    let date: Date
}

enum WateringHistory {

    /// Fixed reference date so tests never depend on the clock.
    static let start = Date(timeIntervalSince1970: 1_740_000_000)

    /// Builds waterings `intervalHours` apart, oldest first.
    static func make(
        _ amounts: [(water: Double, runoff: Double)],
        intervalHours: Double = 48,
        start: Date = WateringHistory.start
    ) -> [TestWatering] {
        amounts.enumerated().map { index, amount in
            TestWatering(
                water: amount.water,
                runoff: amount.runoff,
                date: start.addingTimeInterval(Double(index) * intervalHours * 3600)
            )
        }
    }

    /// Builds waterings at the given hour offsets from `start` (irregular spacing).
    static func make(
        _ amounts: [(water: Double, runoff: Double)],
        atHours hours: [Double],
        start: Date = WateringHistory.start
    ) -> [TestWatering] {
        precondition(amounts.count == hours.count, "one offset per watering")
        return zip(amounts, hours).map { amount, hour in
            TestWatering(water: amount.water, runoff: amount.runoff, date: start.addingTimeInterval(hour * 3600))
        }
    }

    /// `count` identical waterings: 1.20 L added, 0.18 L runoff (15%), 1.02 L retained.
    static func steady(_ count: Int, water: Double = 1.20, runoff: Double = 0.18) -> [(water: Double, runoff: Double)] {
        Array(repeating: (water: water, runoff: runoff), count: count)
    }
}
