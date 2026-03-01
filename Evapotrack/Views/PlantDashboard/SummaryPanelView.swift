// SummaryPanelView.swift
// Evapotrack
//
// Displays the most recent WateringLog's key metrics.
// Shows: Last Event Date, Retained, Capacity %, Interval.
// Empty state when no logs exist.

import SwiftUI

struct SummaryPanelView: View {
    let lastLog: WateringLog?
    let maxRetentionCapacity: Double // liters
    let waterUnit: WaterUnit

    var body: some View {
        Section {
            if let log = lastLog {
                LabeledContent("Last Event Date", value: log.dateTime.shortFormatted)

                LabeledContent("Retained", value: DisplayFormatter.water(log.retained, unit: waterUnit))

                LabeledContent("Max Retention Capacity", value: DisplayFormatter.water(maxRetentionCapacity, unit: waterUnit))

                if maxRetentionCapacity > 0 {
                    LabeledContent("Capacity %", value: DisplayFormatter.percent(
                        WateringCalculationService.capacityPercent(
                            retained: log.retained,
                            maxRetentionCapacity: maxRetentionCapacity
                        )
                    ))
                } else {
                    LabeledContent("Capacity %", value: "—")
                }

                if let hours = log.intervalHours {
                    LabeledContent("Interval", value: DisplayFormatter.intervalAdaptive(hours))
                } else {
                    LabeledContent("Interval", value: "—")
                }
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
        .fontWeight(.medium)
    }
}
