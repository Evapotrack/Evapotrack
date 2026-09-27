// © 2026 Evapotrack. All rights reserved.
// InsightsPanelView.swift
// Evapotrack
//
// Shows the Next-watering recommendation in a compact grid: Expected
// (estimated retention), Next (recommended water) and Goal (expected runoff),
// followed by a short explanation of what Next is based on.
// All values respect unit toggles and display precision rules.

import SwiftUI

struct InsightsPanelView: View {
    let outcome: RecommendationOutcome
    let waterUnit: WaterUnit
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    var body: some View {
        Section {
            switch outcome {
            case .recommendation(let recommendation):
                VStack(alignment: .leading, spacing: 10) {
                    LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
                        metricCell(
                            Strings.expected,
                            DisplayFormatter.water(recommendation.estimatedRetention, unit: waterUnit),
                            spokenLabel: Strings.expectedRetentionLabel
                        )
                        metricCell(
                            Strings.next,
                            DisplayFormatter.water(recommendation.nextWater, unit: waterUnit)
                        )
                        metricCell(
                            Strings.goalLabel(DisplayFormatter.percent(recommendation.goalRunoffPercent)),
                            DisplayFormatter.water(recommendation.goalRunoff, unit: waterUnit)
                        )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(RecommendationText.lines(for: recommendation, unit: waterUnit), id: \.self) { line in
                            Text(line)
                                .font(.callout)
                                .foregroundStyle(Color.evSecondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                .padding(.vertical, 2)

            case .noHistory:
                Text(Strings.insightsNoHistory)
                    .foregroundStyle(Color.evSecondaryText)

            case .noUsableData:
                Text(Strings.insightsNoUsableData)
                    .foregroundStyle(Color.evSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
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

    private func metricCell(_ label: String, _ value: String, spokenLabel: String? = nil) -> some View {
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
        .accessibilityLabel("\(spokenLabel ?? label): \(value)")
    }
}
