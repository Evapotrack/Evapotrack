// InsightsPanelView.swift
// Evapotrack
//
// Shows calculated insights in a compact grid: Average Retained,
// Next (recommended water amount), and Goal Runoff.
// All values respect unit toggles and display precision rules.

import SwiftUI

struct InsightsPanelView: View {
    let averageRetained: Double?                      // internal: liters
    let nextRecommendation: NextWaterRecommendation?  // internal: liters
    let waterUnit: WaterUnit

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Section {
            if let retained = averageRetained, let recommendation = nextRecommendation {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                    metricCell("Average", DisplayFormatter.water(retained, unit: waterUnit))
                    metricCell("Next Amount", DisplayFormatter.water(recommendation.next, unit: waterUnit))
                    metricCell(
                        "Goal Runoff (\(DisplayFormatter.percent(recommendation.goalRunoffPercent)))",
                        DisplayFormatter.water(recommendation.goalRunoff, unit: waterUnit)
                    )
                }
                .padding(.vertical, 4)
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
    }

    private func metricCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.evSecondaryText)
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(Color.evPrimaryText)
        }
    }
}
