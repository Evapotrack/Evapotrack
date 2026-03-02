// SummaryPanelView.swift
// Evapotrack
//
// Displays the most recent WateringLog's key metrics in a compact grid.
// Shows: Last Event, Retained, Max Capacity, Capacity %, Interval.
// Empty state when no logs exist.

import SwiftUI

struct SummaryPanelView: View {
    let lastLog: WateringLog?
    let maxRetentionCapacity: Double // liters
    let waterUnit: WaterUnit

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Section {
            if let log = lastLog {
                LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
                    metricCell("Last Event", log.dateTime.shortFormatted)
                    metricCell("Interval", intervalText(for: log))
                    metricCell("Retained", DisplayFormatter.water(log.retained, unit: waterUnit))
                    metricCell("Capacity", capacityText(for: log))
                    metricCell("Max Capacity", DisplayFormatter.water(maxRetentionCapacity, unit: waterUnit))
                }
                .padding(.vertical, 4)
            } else {
                Text("No watering logs yet.")
                    .foregroundStyle(Color.evSecondaryText)
            }
        } header: {
            Text("Summary")
                .font(.title2.weight(.bold))
                .foregroundStyle(.evDeepNavy)
                .textCase(nil)
        }
    }

    private func metricCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.evSecondaryText)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.evPrimaryBlue)
        }
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
