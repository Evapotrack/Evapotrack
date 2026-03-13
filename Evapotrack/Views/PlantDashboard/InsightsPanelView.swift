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
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Section {
            if let retained = averageRetained, let recommendation = nextRecommendation {
                LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
                    metricCell("Average", DisplayFormatter.water(retained, unit: waterUnit))
                    metricCell("Next", DisplayFormatter.water(recommendation.next, unit: waterUnit))
                    metricCell(
                        "Goal (\(DisplayFormatter.percent(recommendation.goalRunoffPercent)))",
                        DisplayFormatter.water(recommendation.goalRunoff, unit: waterUnit)
                    )
                }
                .padding(.vertical, 4)
            } else {
                Text("No insights yet. Add watering logs to see recommendations.")
                    .foregroundStyle(Color.evSecondaryText)
            }
        } header: {
            Label {
                Text("Insights")
            } icon: {
                Image(systemName: "lightbulb")
            }
            .font(.title2.weight(.bold))
            .foregroundStyle(.evDeepNavy)
            .textCase(nil)
        }
    }

    private func metricCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.evSecondaryText)
            Text(value)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(Color.evPrimaryBlue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.evFrostBlue.opacity(0.08))
        )
    }
}
