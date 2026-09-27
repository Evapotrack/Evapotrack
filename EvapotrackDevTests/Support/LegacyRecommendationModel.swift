// © 2026 Evapotrack. All rights reserved.
// LegacyRecommendationModel.swift
// EvapotrackDevTests
//
// Exact copy of the Next algorithm shipped through commit 89cc8c8
// (PlantDashboardViewModel.averageRetained +
// WateringCalculationService.computeNextWaterRecommendation):
//
//   average  = mean(retained of ALL logs)
//   expected = (retained of newest log + average) / 2
//   next     = min(expected / (1 - goal), maxRetentionCapacity / (1 - goal))
//   nil when the newest log retained nothing
//
// It lives only in the test target, as the reference for characterization
// and comparison tests. The app no longer uses it.

import Foundation

struct LegacyRecommendation: Equatable {
    let next: Double
    let goalRunoff: Double
}

enum LegacyRecommendationModel {

    static func recommend(
        _ history: [TestWatering],
        maxRetentionCapacity: Double,
        goalRunoffPercent: Double = 15.0
    ) -> LegacyRecommendation? {
        guard !history.isEmpty else { return nil }

        // WateringLog.init clamped inputs before storing retained.
        let logs = history.map { watering -> (date: Date, retained: Double) in
            let water = max(watering.water, 0.001)
            let runoff = max(watering.runoff, 0)
            return (watering.date, max(0, water - runoff))
        }

        // The dashboard sorted logs newest first and used the first as "last".
        let newestFirst = logs.sorted { $0.date > $1.date }
        guard let retainedLast = newestFirst.first?.retained, retainedLast > 0 else { return nil }

        let retentionFactor = 1.0 - goalRunoffPercent / 100.0
        guard retentionFactor > 0 else { return nil }

        // Summed newest first, in the same order the dashboard used.
        let average = newestFirst.map(\.retained).reduce(0, +) / Double(newestFirst.count)
        let expectedRetained = (retainedLast + average) / 2.0
        let next = min(expectedRetained / retentionFactor, maxRetentionCapacity / retentionFactor)
        return LegacyRecommendation(next: next, goalRunoff: next * goalRunoffPercent / 100.0)
    }
}
