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
                    metricCell(Strings.average, DisplayFormatter.water(retained, unit: waterUnit))
                    metricCell(Strings.next, DisplayFormatter.water(recommendation.next, unit: waterUnit))
                    metricCell(
                        Strings.goalLabel(DisplayFormatter.percent(recommendation.goalRunoffPercent)),
                        DisplayFormatter.water(recommendation.goalRunoff, unit: waterUnit)
                    )
                }
                .padding(.vertical, 4)
            } else {
                Text(Strings.noInsightsYet)
                    .foregroundStyle(Color.evSecondaryText)
            }
        } header: {
            Label {
                Text(Strings.insights)
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
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.evSecondaryText)
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(Color.evPrimaryBlue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.evFrostBlue.opacity(0.12))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
