// WateringLogRowView.swift
// Evapotrack
//
// A single row in the watering history list with selection indicator.
// Collapsed: shows Time, Water Added, Retained, Capacity % (scannable).
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
                // Time and expand chevron
                HStack {
                    Text(log.dateTime.timeFormatted)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.evDeepNavy)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.evSlateGray)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .accessibilityLabel(isExpanded ? "Collapse" : "Expand")
                }
                .font(.body)

                // Collapsed summary: key metrics at a glance
                HStack(spacing: 12) {
                    compactMetric(DisplayFormatter.water(log.waterAdded, unit: waterUnit), label: "added")
                    compactMetric(DisplayFormatter.water(log.retained, unit: waterUnit), label: "retained")
                    Spacer()
                    Text(DisplayFormatter.percent(capacityPercent))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.evPrimaryBlue)
                }

                // Expanded detail fields
                if isExpanded {
                    VStack(alignment: .leading, spacing: 0) {
                        Divider()
                            .padding(.vertical, 2)
                        fieldRow("Water Added", DisplayFormatter.water(log.waterAdded, unit: waterUnit), shaded: true)
                        fieldRow("Runoff Collected", DisplayFormatter.water(log.runoffCollected, unit: waterUnit), shaded: false)
                        fieldRow("Retained", DisplayFormatter.water(log.retained, unit: waterUnit), shaded: true)
                        fieldRow("Runoff %", DisplayFormatter.percent(log.runoffPercent), shaded: false)
                        fieldRow("Capacity %", DisplayFormatter.percent(capacityPercent), shaded: true)
                        fieldRow("Interval", intervalText, shaded: false)
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
            .accessibilityLabel(isExpanded ? "Collapse log details" : "Expand log details")
            .accessibilityAddTraits(.isButton)
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

    private func fieldRow(_ label: String, _ value: String, shaded: Bool = false) -> some View {
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
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(shaded ? Color.evFrostBlue.opacity(0.12) : Color.clear)
        )
    }
}
