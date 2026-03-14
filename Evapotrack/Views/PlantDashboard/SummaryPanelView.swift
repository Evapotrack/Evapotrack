// SummaryPanelView.swift
// Evapotrack
//
// Displays the most recent WateringLog's key metrics in a compact grid.
// Shows: Last Event, Interval, Retained, Capacity %.
// Empty state when no logs exist.

import SwiftUI

struct SummaryPanelView: View {
    let lastLog: WateringLog?
    let maxRetentionCapacity: Double
    let waterUnit: WaterUnit
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    var body: some View {
        Section {
            if let log = lastLog {
                LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
                    metricCell("Last Event", log.dateTime.shortFormatted)
                    metricCell("Interval", intervalText(for: log))
                    metricCell("Retained", DisplayFormatter.water(log.retained, unit: waterUnit))
                    metricCell("Capacity", capacityText(for: log))
                }
                .padding(.vertical, 4)
            } else {
                Text("No watering logs yet.")
                    .foregroundStyle(Color.evSecondaryText)
            }
        } header: {
            Label {
                Text("Summary")
            } icon: {
                Image(systemName: "list.clipboard")
            }
            .font(.title2.weight(.bold))
            .foregroundStyle(.evDeepNavy)
            .textCase(nil)
        }
    }

    private func metricCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(Color.evSecondaryText)
            Text(value)
                .font(.title3)
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

    private func capacityText(for log: WateringLog) -> String {
        guard maxRetentionCapacity > 0 else { return "—" }
        return DisplayFormatter.percent(
            WateringCalculationService.capacityPercent(
                retained: log.retained,
                maxRetentionCapacity: maxRetentionCapacity
            )
        )
    }

    private func intervalText(for log: WateringLog) -> String {
        if let hours = log.intervalHours {
            return DisplayFormatter.intervalAdaptive(hours)
        }
        return "—"
    }
}
