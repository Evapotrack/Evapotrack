// WateringLogRowView.swift
// Evapotrack
//
// A single row in the watering history list with selection indicator.
// Collapsed: shows Date, Time, Water Added, Retained (scannable).
// Expanded: reveals Runoff Collected, Runoff %, Capacity %, Interval.
// Tap row content to expand/collapse. Tap circle to select.
// Expansion state managed by parent — only one row expanded at a time.

import SwiftUI

struct WateringLogRowView: View {
    let log: WateringLog
    let waterUnit: WaterUnit
    let maxRetentionCapacity: Double // liters — for Capacity %
    let isSelected: Bool
    let isExpanded: Bool
    let onToggleSelection: () -> Void
    let onToggleExpansion: () -> Void

    private var capacityPercent: Double {
        WateringCalculationService.capacityPercent(
            retained: log.retained,
            maxRetentionCapacity: maxRetentionCapacity
        )
    }

    private var intervalText: String {
        if let hours = log.intervalHours {
            return DisplayFormatter.intervalAdaptive(hours)
        }
        return "—"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left-side circular selection indicator
            Button {
                onToggleSelection()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? Color.evPrimaryBlue : Color.evSlateGray)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSelected ? "Deselect log" : "Select log")

            // Tappable content area
            VStack(alignment: .leading, spacing: 6) {
                // Date, Time, and expand chevron
                HStack {
                    Text(log.dateTime.shortFormatted)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(log.dateTime.timeFormatted)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.evSlateGray)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .accessibilityLabel(isExpanded ? "Collapse" : "Expand")
                }
                .font(.body)
                .foregroundStyle(Color.evPrimaryText)

                // Collapsed summary: key metrics at a glance
                HStack(spacing: 16) {
                    compactMetric(DisplayFormatter.water(log.waterAdded, unit: waterUnit), label: "added")
                    compactMetric(DisplayFormatter.water(log.retained, unit: waterUnit), label: "retained")
                }

                // Expanded detail fields
                if isExpanded {
                    VStack(alignment: .leading, spacing: 4) {
                        Divider()
                            .padding(.vertical, 2)
                        fieldRow("Water Added", DisplayFormatter.water(log.waterAdded, unit: waterUnit))
                        fieldRow("Runoff Collected", DisplayFormatter.water(log.runoffCollected, unit: waterUnit))
                        fieldRow("Retained", DisplayFormatter.water(log.retained, unit: waterUnit))
                        fieldRow("Runoff %", DisplayFormatter.percent(log.runoffPercent))
                        fieldRow("Capacity %", DisplayFormatter.percent(capacityPercent))
                        fieldRow("Interval", intervalText)
                    }
                    .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    onToggleExpansion()
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func compactMetric(_ value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(Color.evPrimaryText)
            Text(label)
                .foregroundStyle(Color.evSlateGray)
        }
        .font(.body)
    }

    private func fieldRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
                .foregroundStyle(Color.evSecondaryText)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(Color.evPrimaryText)
        }
        .font(.body)
    }
}
