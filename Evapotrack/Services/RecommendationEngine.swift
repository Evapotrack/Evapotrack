// © 2026 Evapotrack. All rights reserved.
// RecommendationEngine.swift
// Evapotrack
//
// Estimates how much water a plant will retain at its next watering and
// turns that estimate into a Next amount that should produce the plant's
// goal runoff.
//
// What is estimated: the plant's current retention demand, the volume the
// medium absorbs before free drainage (runoff) starts.
//   - A watering WITH runoff measures it: retained = water added - runoff.
//   - A watering with NO runoff only proves the demand was at least the
//     water added (a censored, lower-bound observation).
//   - A watering that drained COMPLETELY retained nothing measurable and is
//     not used for the estimate.
//
// Model (chosen with closed-loop simulations; see the engineering report):
//   - level + damped trend over waterings with runoff (Holt's method),
//   - a no-runoff watering raises the estimate to at least its water added,
//   - one watering can lower the forecast by at most 25%, so a small top-up
//     cannot drag Next down,
//   - the trend contributes at most +/-25% of the level.
// Next = min(estimate, Max Retention Capacity) / (1 - goal), with the goal
// limited to the supported range and Next limited to the largest watering
// the app records.
//
// Pure and deterministic: no SwiftUI, persistence, UserDefaults or
// formatting. All volumes are liters.

import Foundation

// MARK: - Input

/// One logged watering as the engine sees it. Volumes are liters.
nonisolated struct WateringObservation: Equatable, Sendable {
    let waterAdded: Double
    let runoff: Double
    let date: Date
}

/// How a single watering can be used for estimation.
nonisolated enum ObservationKind: Equatable, Sendable {
    /// Runoff occurred, so the retained water measures the demand.
    case measured(retained: Double)
    /// No runoff: the demand was at least the water added.
    case noRunoff(waterAdded: Double)
    /// Everything drained: nothing retained, not used.
    case fullRunoff
    /// Non-finite or impossible values: ignored.
    case invalid

    init(_ observation: WateringObservation) {
        let water = observation.waterAdded
        let runoff = observation.runoff
        if !water.isFinite || !runoff.isFinite || water <= 0 || runoff < 0 {
            self = .invalid
        } else if runoff >= water {
            self = .fullRunoff
        } else if runoff == 0 {
            self = .noRunoff(waterAdded: water)
        } else {
            self = .measured(retained: water - runoff)
        }
    }
}

// MARK: - Output

nonisolated enum RecommendationOutcome: Equatable, Sendable {
    /// No watering logs yet.
    case noHistory
    /// Logs exist, but none retained measurable water (all drained completely).
    case noUsableData
    case recommendation(Recommendation)
}

nonisolated struct Recommendation: Equatable, Sendable {
    /// Recommended water for the next watering, liters.
    let nextWater: Double
    /// Runoff expected from `nextWater` at the goal, liters.
    let goalRunoff: Double
    /// Goal runoff % actually used (after limiting to the supported range).
    let goalRunoffPercent: Double
    /// Estimated retention demand used for Next (after the capacity limit), liters.
    let estimatedRetention: Double
    let basis: RecommendationBasis
    /// Reasons that explain or qualify the recommendation, in display order.
    let notes: [RecommendationNote]
}

nonisolated enum RecommendationBasis: Equatable, Sendable {
    /// Estimated from waterings that produced runoff.
    case measured(wateringsWithRunoff: Int)
    /// No watering has produced runoff yet; the estimate is a lower bound.
    case noRunoffYet
}

nonisolated enum RecommendationNote: Equatable, Sendable {
    /// The latest watering produced no runoff. `raisedEstimate` says whether it
    /// raised the estimate (it was more than the plant usually takes).
    case lastWateringNoRunoff(waterAdded: Double, raisedEstimate: Bool)
    /// The latest watering drained completely and was not used.
    case lastWateringFullRunoff
    /// Recent waterings show the plant taking more water.
    case demandRising
    /// Recent waterings show the plant taking less water.
    case demandFalling
    /// The estimate was limited to the plant's Max Retention Capacity.
    case limitedByCapacity(capacity: Double)
    /// The plant's goal runoff was outside the supported range (or invalid).
    case goalAdjusted(requestedPercent: Double)
    /// Next was limited to the largest watering the app records.
    case limitedByMaximumWater(maximum: Double)
}

// MARK: - Engine

nonisolated enum RecommendationEngine {

    /// Weight of the newest measurement in the level (Holt alpha).
    static let levelSmoothing = 0.5
    /// Weight of the newest level change in the trend (Holt beta).
    static let trendSmoothing = 0.2
    /// Share of the trend carried forward each watering (damping phi).
    static let trendDamping = 0.8
    /// One watering can lower the forecast by at most this fraction.
    static let maxDropPerWatering = 0.25
    /// The trend can move the forecast by at most this fraction of the level.
    static let maxTrendShare = 0.25
    /// A trend at least this share of the level is mentioned to the grower.
    static let notableTrendShare = 0.05

    static func recommend(
        observations: [WateringObservation],
        maxRetentionCapacity: Double,
        goalRunoffPercent: Double
    ) -> RecommendationOutcome {
        guard !observations.isEmpty else { return .noHistory }

        // Oldest first; waterings with the same date keep their input order.
        let chronological = observations.enumerated()
            .sorted { lhs, rhs in
                lhs.element.date == rhs.element.date
                    ? lhs.offset < rhs.offset
                    : lhs.element.date < rhs.element.date
            }
            .map { $0.element }

        var state = EstimatorState()
        var lastKind = ObservationKind.invalid
        var lastRaisedEstimate = false
        for observation in chronological {
            let kind = ObservationKind(observation)
            lastRaisedEstimate = state.update(with: kind)
            lastKind = kind
        }

        guard let level = state.level else { return .noUsableData }

        var notes: [RecommendationNote] = []
        switch lastKind {
        case .noRunoff(let water):
            notes.append(.lastWateringNoRunoff(waterAdded: water, raisedEstimate: lastRaisedEstimate))
        case .fullRunoff:
            notes.append(.lastWateringFullRunoff)
        case .measured, .invalid:
            break
        }

        let forecastRetention = forecast(level: level, trend: state.trend)
        let trendPart = forecastRetention - level
        if trendPart >= notableTrendShare * level {
            notes.append(.demandRising)
        } else if trendPart <= -notableTrendShare * level {
            notes.append(.demandFalling)
        }

        var estimate = forecastRetention
        if maxRetentionCapacity.isFinite, maxRetentionCapacity > 0, estimate > maxRetentionCapacity {
            estimate = maxRetentionCapacity
            notes.append(.limitedByCapacity(capacity: maxRetentionCapacity))
        }

        let goal = effectiveGoal(goalRunoffPercent)
        if goal != goalRunoffPercent {
            notes.append(.goalAdjusted(requestedPercent: goalRunoffPercent))
        }

        var next = estimate / (1.0 - goal / 100.0)
        let maximum = AppConstants.waterAddedRange.upperBound
        if next > maximum {
            next = maximum
            notes.append(.limitedByMaximumWater(maximum: maximum))
        }
        guard next.isFinite, next > 0 else { return .noUsableData }

        let basis: RecommendationBasis = state.measuredCount > 0
            ? .measured(wateringsWithRunoff: state.measuredCount)
            : .noRunoffYet

        return .recommendation(Recommendation(
            nextWater: next,
            goalRunoff: next * goal / 100.0,
            goalRunoffPercent: goal,
            estimatedRetention: estimate,
            basis: basis,
            notes: notes
        ))
    }

    /// Goal runoff % used for Next: limited to the supported range, and the
    /// default when the stored value is not a number.
    static func effectiveGoal(_ requested: Double) -> Double {
        guard requested.isFinite else { return AppConstants.targetRunoffPercent }
        let range = AppConstants.goalRunoffPercentRange
        return min(max(requested, range.lowerBound), range.upperBound)
    }

    /// Level plus the damped trend, with the trend limited to +/-25% of the level.
    static func forecast(level: Double, trend: Double) -> Double {
        let limit = maxTrendShare * level
        return level + min(max(trendDamping * trend, -limit), limit)
    }
}

// MARK: - Estimator State

/// Running level-and-trend estimate over a chronological history.
nonisolated private struct EstimatorState {
    var level: Double?
    var trend = 0.0
    var measuredCount = 0

    /// Folds one watering into the estimate. Returns true when a no-runoff
    /// watering raised the estimate.
    mutating func update(with kind: ObservationKind) -> Bool {
        switch kind {
        case .measured(let retained):
            if let level, measuredCount > 0 {
                let predicted = RecommendationEngine.forecast(level: level, trend: trend)
                let lowestAccepted = predicted * (1.0 - RecommendationEngine.maxDropPerWatering)
                let effective = max(retained, lowestAccepted)
                let alpha = RecommendationEngine.levelSmoothing
                let beta = RecommendationEngine.trendSmoothing
                let newLevel = alpha * effective + (1.0 - alpha) * predicted
                trend = beta * (newLevel - level) + (1.0 - beta) * RecommendationEngine.trendDamping * trend
                self.level = newLevel
            } else {
                // The first watering with runoff is a direct measurement and
                // replaces any lower bound from earlier no-runoff waterings.
                self.level = retained
                trend = 0
            }
            measuredCount += 1
            return false

        case .noRunoff(let water):
            guard let level else {
                self.level = water
                trend = 0
                return true
            }
            guard water > RecommendationEngine.forecast(level: level, trend: trend) else { return false }
            self.level = water
            trend = max(trend, 0)
            return true

        case .fullRunoff, .invalid:
            return false
        }
    }
}
