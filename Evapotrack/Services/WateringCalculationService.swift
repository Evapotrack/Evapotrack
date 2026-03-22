// © 2026 Evapotrack. All rights reserved.
// WateringCalculationService.swift
// Evapotrack
//
// Core calculation logic for watering amounts.
// Provides interval-hours recalculation, capacity tracking,
// and next-water-amount recommendations.

import Foundation

// MARK: - Next Water Recommendation

struct NextWaterRecommendation {
    /// Recommended next water amount, in liters.
    let next: Double
    /// Estimated goal runoff for the recommended amount, in liters.
    let goalRunoff: Double
    /// The goal runoff percentage used for this recommendation.
    let goalRunoffPercent: Double
}

// MARK: - Service

enum WateringCalculationService {

    // MARK: - Interval Hours Recalculation

    /// Recalculate intervalHours for all logs belonging to a plant.
    /// The oldest log gets nil; each subsequent log gets the hours since the previous.
    /// WateringLog is a reference type, so mutations apply to the originals.
    static func recalculateIntervalHours(for logs: [WateringLog]) {
        let sorted = logs.sorted { $0.dateTime < $1.dateTime }
        for (index, log) in sorted.enumerated() {
            if index == 0 {
                log.intervalHours = nil
            } else {
                log.intervalHours = max(0, Date.hoursBetween(
                    start: sorted[index - 1].dateTime,
                    end: log.dateTime
                ))
            }
        }
    }

    // MARK: - Capacity Percent

    /// Capacity % = (retained / maxRetentionCapacity) × 100, capped at 105%.
    /// All inputs in internal units (liters).
    static func capacityPercent(retained: Double, maxRetentionCapacity: Double) -> Double {
        guard maxRetentionCapacity > 0 else { return 0 }
        let raw = (retained / maxRetentionCapacity) * 100.0
        return min(raw, AppConstants.maxCapacityPercent)
    }

    // MARK: - Next Water Recommendation

    /// Compute the recommended next water amount using the Insights algorithm.
    /// All calculations in internal units (liters). Returns nil if retained_last <= 0.
    ///
    /// Algorithm:
    /// 1. Estimate expected retention by averaging the most recent retained
    ///    amount with the historical average (50/50 blend).
    /// 2. Next = expectedRetained / (1 - goalRunoffPercent/100)
    /// 3. Cap Next so it never exceeds what maxRetentionCapacity would require.
    /// 4. GoalRunoff = Next * (goalRunoffPercent / 100)
    static func computeNextWaterRecommendation(
        lastLog: WateringLog,
        averageRetained: Double,
        maxRetentionCapacity: Double,
        goalRunoffPercent: Double = AppConstants.targetRunoffPercent
    ) -> NextWaterRecommendation? {
        let retainedLast = lastLog.retained
        guard retainedLast > 0 else { return nil }

        let retentionFactor = 1.0 - goalRunoffPercent / 100.0
        guard retentionFactor > 0 else { return nil }

        let expectedRetained = (retainedLast + averageRetained) / 2.0
        var next = expectedRetained / retentionFactor

        let maxSafeWater = maxRetentionCapacity / retentionFactor
        next = min(next, maxSafeWater)

        let goalRunoff = next * (goalRunoffPercent / 100.0)
        return NextWaterRecommendation(next: next, goalRunoff: goalRunoff, goalRunoffPercent: goalRunoffPercent)
    }
}
