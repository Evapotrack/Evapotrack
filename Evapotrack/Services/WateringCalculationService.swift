// © 2026 Evapotrack. All rights reserved.
// WateringCalculationService.swift
// Evapotrack
//
// Calculations on logged waterings: interval-hours recalculation and
// capacity percentage. The Next recommendation lives in
// RecommendationEngine.

import Foundation

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

    /// Capacity % = (retained / maxRetentionCapacity) × 100: how much of the
    /// medium's full capacity this watering refilled. Not capped: above 100%
    /// means the watering retained more than the plant's Max Retention
    /// Capacity, a sign the capacity is set too low. All inputs in liters.
    static func capacityPercent(retained: Double, maxRetentionCapacity: Double) -> Double {
        guard maxRetentionCapacity > 0, retained.isFinite else { return 0 }
        return max(0, retained / maxRetentionCapacity * 100.0)
    }
}
