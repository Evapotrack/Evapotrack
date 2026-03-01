// InsightsPanelView.swift
// Evapotrack
//
// Shows calculated insights: Average Retained, Next (recommended
// water amount), and Runoff (Insights). All values respect unit
// toggles and display precision rules.

import SwiftUI

struct InsightsPanelView: View {
    let averageRetained: Double?                      // internal: liters
    let nextRecommendation: NextWaterRecommendation?  // internal: liters
    let waterUnit: WaterUnit

    var body: some View {
        Section {
            if let retained = averageRetained, let recommendation = nextRecommendation {
                LabeledContent("Average", value: DisplayFormatter.water(retained, unit: waterUnit))
                LabeledContent("Next Watering Amount", value: DisplayFormatter.water(recommendation.next, unit: waterUnit))
                LabeledContent(
                    "Goal Runoff (\(DisplayFormatter.percent(recommendation.goalRunoffPercent)))",
                    value: DisplayFormatter.water(recommendation.goalRunoff, unit: waterUnit)
                )
            } else {
                Text("No insights yet. Add watering logs to see recommendations.")
                    .foregroundStyle(Color.evSecondaryText)
            }
        } header: {
            Text("Insights")
                .font(.title2.weight(.bold))
                .foregroundStyle(.evDeepNavy)
                .textCase(nil)
        }
        .fontWeight(.medium)
    }
}
