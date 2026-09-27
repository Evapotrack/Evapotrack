// © 2026 Evapotrack. All rights reserved.
// RecommendationText.swift
// Evapotrack
//
// Turns a Recommendation's basis and notes into short, localized sentences
// for the Insights panel. Formatting lives here so the engine stays free of
// UI concerns.

import Foundation

enum RecommendationText {

    static func lines(for recommendation: Recommendation, unit: WaterUnit) -> [String] {
        var lines: [String] = []
        let goal = DisplayFormatter.percent(recommendation.goalRunoffPercent)
        let estimate = DisplayFormatter.water(recommendation.estimatedRetention, unit: unit)

        switch recommendation.basis {
        case .measured(let count):
            lines.append(count == 1
                ? Strings.basisSingleWatering(estimate, goal: goal)
                : Strings.basisRecentWaterings(estimate, goal: goal))
        case .noRunoffYet:
            lines.append(Strings.basisNoRunoffYet(estimate))
        }

        for note in recommendation.notes {
            switch note {
            case .lastWateringNoRunoff(let water, let raisedEstimate):
                // With no runoff yet, the basis sentence already explains this.
                if case .noRunoffYet = recommendation.basis { continue }
                let amount = DisplayFormatter.water(water, unit: unit)
                lines.append(raisedEstimate
                    ? Strings.noteNoRunoffRaised(amount)
                    : Strings.noteNoRunoffNotLowered(amount))
            case .lastWateringFullRunoff:
                lines.append(Strings.noteFullRunoff)
            case .demandRising:
                lines.append(Strings.noteDemandRising)
            case .demandFalling:
                lines.append(Strings.noteDemandFalling)
            case .limitedByCapacity(let capacity):
                lines.append(Strings.noteLimitedByCapacity(DisplayFormatter.water(capacity, unit: unit)))
            case .goalAdjusted(let requested):
                let requestedText = requested.isFinite ? DisplayFormatter.percent(requested) : "—"
                lines.append(Strings.noteGoalAdjusted(requestedText, used: goal))
            case .limitedByMaximumWater(let maximum):
                lines.append(Strings.noteLimitedByMaximumWater(DisplayFormatter.water(maximum, unit: unit)))
            }
        }
        return lines
    }
}
