// © 2026 Evapotrack. All rights reserved.
// WateringLogRowView.swift
// Evapotrack
//
// A single row in the watering history list with selection indicator.
// Collapsed: shows Time, Water Added, Retained, Capacity % (scannable), and
// a photo symbol when the log has a photo.
// Expanded: reveals Runoff Collected, Runoff %, Capacity %, Interval, and
// the photo's thumbnail, which opens the full-screen viewer.
// Tap row content to expand/collapse. Tap circle to select.
// Expansion state managed by parent — only one row expanded at a time.
// VoiceOver reads the summary as one element (with its values), each detail
// field as one element, and offers "View photo" as an action.

import SwiftUI

struct WateringLogRowView: View {
    let log: WateringLog
    let waterUnit: WaterUnit
    let temperatureUnit: TemperatureUnit
    let maxRetentionCapacity: Double // liters — for Capacity %
    let isSelected: Bool
    let isExpanded: Bool
    let onToggleSelection: () -> Void
    let onToggleExpansion: () -> Void
    let onOpenPhoto: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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

    private var photoID: UUID? { log.photoFileID }

    private var summaryAccessibilityLabel: String {
        Strings.logRowAccessibility(
            time: log.dateTime.timeFormatted,
            added: DisplayFormatter.water(log.waterAdded, unit: waterUnit),
            retained: DisplayFormatter.water(log.retained, unit: waterUnit),
            capacity: DisplayFormatter.percent(capacityPercent),
            hasPhoto: photoID != nil
        )
    }

    var body: some View {
        HStack(alignment: .top, spacing: 2) {
            // Left-side circular selection indicator. The 44 pt frame keeps
            // the symbol where it was and enlarges only the tap target.
            Button {
                onToggleSelection()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? Color.evPrimaryBlue : Color.evSlateGray)
                    .frame(minWidth: 44, minHeight: 44, alignment: .top)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSelected ? Strings.deselectLog : Strings.selectLog)
            .accessibilityValue(log.dateTime.timeFormatted)
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            VStack(alignment: .leading, spacing: 4) {
                // Tappable content area
                VStack(alignment: .leading, spacing: 4) {
                    summary
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(summaryAccessibilityLabel)
                        .accessibilityValue(isExpanded ? Strings.expanded : Strings.collapsed)
                        .accessibilityHint(Strings.doubleTapExpandCollapse)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                onToggleExpansion()
                            }
                        }
                        .accessibilityActions {
                            if photoID != nil {
                                Button(Strings.viewPhoto) { onOpenPhoto() }
                            }
                        }

                    // Expanded detail fields
                    if isExpanded {
                        details
                            .transition(.opacity)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        onToggleExpansion()
                    }
                }

                // Outside the tappable area so tapping the photo opens it
                // instead of collapsing the row.
                if isExpanded, let photoID {
                    Button {
                        onOpenPhoto()
                    } label: {
                        WateringPhotoThumbnail(source: .stored(photoID))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                    .accessibilityLabel(Strings.viewPhoto)
                    .accessibilityHint(Strings.viewPhotoHint)
                    .transition(.opacity)
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Summary

    private var summary: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Time, photo symbol and expand chevron
            HStack(spacing: 6) {
                Text(log.dateTime.timeFormatted)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.evDeepNavy)
                if photoID != nil {
                    Image(systemName: "photo")
                        .font(.callout)
                        .foregroundStyle(Color.evSlateGray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.evSlateGray)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .font(.body)

            // Collapsed summary: key metrics at a glance
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 0) {
                        Text(DisplayFormatter.water(log.waterAdded, unit: waterUnit))
                            .fontWeight(.medium)
                            .foregroundStyle(Color.evPrimaryText)
                        Text(Strings.added)
                            .foregroundStyle(Color.evSlateGray)
                    }
                    HStack(spacing: 0) {
                        Text(DisplayFormatter.water(log.retained, unit: waterUnit))
                            .fontWeight(.medium)
                            .foregroundStyle(Color.evPrimaryText)
                        Text(Strings.ret)
                            .foregroundStyle(Color.evSlateGray)
                    }
                    Text(DisplayFormatter.percent(capacityPercent))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.evPrimaryBlue)
                }
                .font(.callout)
            } else {
                HStack(spacing: 0) {
                    Text(DisplayFormatter.water(log.waterAdded, unit: waterUnit))
                        .fontWeight(.medium)
                        .foregroundStyle(Color.evPrimaryText)
                    Text(Strings.added)
                        .foregroundStyle(Color.evSlateGray)

                    Text("  ·  ")
                        .foregroundStyle(Color.evSlateGray)

                    Text(DisplayFormatter.water(log.retained, unit: waterUnit))
                        .fontWeight(.medium)
                        .foregroundStyle(Color.evPrimaryText)
                    Text(Strings.ret)
                        .foregroundStyle(Color.evSlateGray)

                    Spacer()

                    Text(DisplayFormatter.percent(capacityPercent))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.evPrimaryBlue)
                }
                .font(.callout)
                .lineLimit(1)
            }
        }
    }

    // MARK: - Details

    private var details: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .padding(.vertical, 4)
                .accessibilityHidden(true)
            fieldRow(Strings.waterAdded, DisplayFormatter.water(log.waterAdded, unit: waterUnit), shaded: true)
            fieldRow(Strings.runoffCollected, DisplayFormatter.water(log.runoffCollected, unit: waterUnit), shaded: false)
            fieldRow(Strings.retained, DisplayFormatter.water(log.retained, unit: waterUnit), shaded: true)
            fieldRow(Strings.runoffPercent, DisplayFormatter.percent(log.runoffPercent), shaded: false)
            fieldRow(Strings.capacityPercent, DisplayFormatter.percent(capacityPercent), shaded: true)
            fieldRow(Strings.interval, intervalText, shaded: false)
            if let temp = log.temperatureCelsius {
                fieldRow(Strings.temperature, DisplayFormatter.temperature(temp, unit: temperatureUnit), shaded: true)
            }
            if let humidity = log.humidityPercent {
                fieldRow(Strings.humidity, DisplayFormatter.percent(humidity), shaded: log.temperatureCelsius == nil)
            }
        }
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
        .font(.callout)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(shaded ? Color.evFrostBlue.opacity(0.12) : Color.clear)
        )
        .accessibilityElement(children: .combine)
    }
}
