// WateringCalculationService.swift
// Evapotrack
//
// Core calculation logic for watering interval tracking.
// Works with WateringLog's intervalHours and provides
// plant status, next watering date, and history-based
// interval recommendations.

import Foundation

// MARK: - Plant Status

enum PlantStatus: Equatable {
    case neverWatered
    case healthy(daysRemaining: Int)
    case dueSoon(daysRemaining: Int)
    case overdue(daysOverdue: Int)
}

// MARK: - Watering Event (lightweight value for calculations)

struct WateringEvent {
    let date: Date
    let volumeLiters: Double

    init(date: Date = Date(), volumeLiters: Double) {
        self.date = date
        self.volumeLiters = volumeLiters
    }
}

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

    // MARK: - Interval Computation (formula-based)

    /// Base intervals per plant/medium type in days.
    private static let baseIntervals: [String: Double] = [
        "soil": 7.0,
        "perlite": 4.0,
        "coco coir": 5.0,
        "leca": 6.0,
        "sphagnum moss": 5.0,
        "pumice": 5.0,
        "vermiculite": 6.0
    ]

    private static let defaultBaseInterval = 7.0
    private static let referencePotDiameterCm = 15.0
    private static let potSizeCoefficient = 0.02
    private static let indoorFactor = 1.2
    private static let outdoorFactor = 0.8
    private static let referenceVolume = 0.25
    private static let volumeCoefficient = 0.3
    private static let minimumIntervalDays = 1.0
    private static let maximumIntervalDays = 60.0

    /// Compute a recommended interval in days from plant parameters.
    static func computeRecommendedInterval(
        plantType: String,
        potDiameterCm: Double,
        isIndoor: Bool,
        averageVolumeLiters: Double
    ) -> Double {
        let base = baseIntervals[plantType.lowercased()] ?? defaultBaseInterval
        let potFactor = 1.0 + potSizeCoefficient * (potDiameterCm - referencePotDiameterCm)
        let envFactor = isIndoor ? indoorFactor : outdoorFactor
        let volFactor = 1.0 + volumeCoefficient * log(max(averageVolumeLiters, 0.001) / referenceVolume)
        let result = base * potFactor * envFactor * volFactor
        return min(max(result, minimumIntervalDays), maximumIntervalDays)
    }

    // MARK: - Plant Status

    /// Determine the watering status for a plant.
    static func plantStatus(
        lastWateredDate: Date?,
        recommendedIntervalDays: Double,
        dateProvider: DateProviding
    ) -> PlantStatus {
        guard let lastWatered = lastWateredDate else {
            return .neverWatered
        }
        let daysSince = Date.daysBetween(start: lastWatered, end: dateProvider.now)
        let remaining = Int(recommendedIntervalDays) - daysSince
        if remaining > 2 {
            return .healthy(daysRemaining: remaining)
        } else if remaining >= 0 {
            return .dueSoon(daysRemaining: remaining)
        } else {
            return .overdue(daysOverdue: abs(remaining))
        }
    }

    // MARK: - Next Watering Date

    static func nextWateringDate(
        lastWateredDate: Date,
        recommendedIntervalDays: Double
    ) -> Date {
        Calendar.current.date(
            byAdding: .day,
            value: Int(recommendedIntervalDays),
            to: lastWateredDate
        ) ?? lastWateredDate
    }

    // MARK: - Days Until Next Watering

    static func daysUntilNextWatering(
        lastWateredDate: Date,
        recommendedIntervalDays: Double,
        dateProvider: DateProviding
    ) -> Int {
        let next = nextWateringDate(
            lastWateredDate: lastWateredDate,
            recommendedIntervalDays: recommendedIntervalDays
        )
        return Date.daysBetween(start: dateProvider.now, end: next)
    }

    // MARK: - History-Based Recalculation

    /// Recalculate interval blending formula with actual watering history.
    static func recalculateIntervalFromHistory(
        events: [WateringEvent],
        plantType: String,
        potDiameterCm: Double,
        isIndoor: Bool
    ) -> Double {
        let avgVol = averageVolume(from: events)
        let effectiveVol = avgVol > 0 ? avgVol : referenceVolume

        let formulaInterval = computeRecommendedInterval(
            plantType: plantType,
            potDiameterCm: potDiameterCm,
            isIndoor: isIndoor,
            averageVolumeLiters: effectiveVol
        )

        guard events.count >= AppConstants.minimumLogsForBlending else {
            return formulaInterval
        }

        let sorted = events.sorted { $0.date > $1.date }
        var intervals: [Double] = []
        for i in 0..<(sorted.count - 1) {
            let days = abs(Date.daysBetween(start: sorted[i].date, end: sorted[i + 1].date))
            if days > 0 {
                intervals.append(Double(days))
            }
        }

        guard !intervals.isEmpty else { return formulaInterval }

        let actualAvg = intervals.reduce(0, +) / Double(intervals.count)
        precondition(abs(AppConstants.blendingWeightSum - 1.0) < 0.001,
                     "formulaWeight + historyWeight must equal 1.0")
        let blended = formulaInterval * AppConstants.formulaWeight + actualAvg * AppConstants.historyWeight
        return min(max(blended, minimumIntervalDays), maximumIntervalDays)
    }

    // MARK: - Average Volume

    /// Average volume from the most recent `limit` events.
    static func averageVolume(from events: [WateringEvent], limit: Int? = nil) -> Double {
        guard !events.isEmpty else { return 0 }
        let sorted = events.sorted { $0.date > $1.date }
        let subset = limit.map { Array(sorted.prefix($0)) } ?? sorted
        guard !subset.isEmpty else { return 0 }
        return subset.map(\.volumeLiters).reduce(0, +) / Double(subset.count)
    }

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
