// © 2026 Evapotrack. All rights reserved.
// WateringLogRowView.swift
// Evapotrack
//
// A single row in the watering history list with selection indicator.
// Collapsed: shows Time, Water Added, Retained, Capacity % (scannable).
// Expanded: reveals Runoff Collected, Runoff %, Capacity %, Interval.
// Tap row content to expand/collapse. Tap circle to select.
// Expansion state managed by parent — only one row expanded at a time.

import SwiftUI
import UIKit

struct WateringLogRowView: View {
    let log: WateringLog
    let waterUnit: WaterUnit
    let temperatureUnit: TemperatureUnit
    let maxRetentionCapacity: Double // liters — for Capacity %
    let isSelected: Bool
    let isExpanded: Bool
    let onToggleSelection: () -> Void
    let onToggleExpansion: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var photoThumbnail: UIImage?
    @State private var isShowingPhotoViewer = false

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
            .accessibilityLabel(isSelected ? Strings.deselectLog : Strings.selectLog)

            // Tappable content area
            VStack(alignment: .leading, spacing: 4) {
                // Time and expand chevron
                HStack {
                    Text(log.dateTime.timeFormatted)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.evDeepNavy)
                    if log.photoData != nil {
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .foregroundStyle(Color.evSlateGray)
                            .accessibilityLabel(Strings.hasPhotoLabel)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.evSlateGray)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .accessibilityHidden(true)
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
                            .accessibilityLabel(Strings.capacityAccessibility(DisplayFormatter.percent(capacityPercent)))
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
                            .accessibilityLabel(Strings.capacityAccessibility(DisplayFormatter.percent(capacityPercent)))
                    }
                    .font(.callout)
                    .lineLimit(1)
                }

                // Expanded detail fields
                if isExpanded {
                    VStack(alignment: .leading, spacing: 0) {
                        Divider()
                            .padding(.vertical, 4)
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
                        if log.photoData != nil {
                            photoRow
                        }
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
            .accessibilityLabel(isExpanded ? Strings.collapseLogDetails : Strings.expandLogDetails)
            .accessibilityHint(Strings.doubleTapExpandCollapse)
            .accessibilityAddTraits(.isButton)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Photo

    /// Thumbnail of the log's photo shown in the expanded state.
    /// Tapping opens the full-screen zoomable viewer.
    @ViewBuilder
    private var photoRow: some View {
        Button {
            isShowingPhotoViewer = true
        } label: {
            Group {
                if let thumbnail = photoThumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.evFrostBlue.opacity(0.12)
                        .overlay { ProgressView() }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(.black.opacity(0.45), in: Circle())
                    .padding(6)
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .accessibilityLabel(Strings.viewPhoto)
        .task(id: log.id) {
            guard photoThumbnail == nil, let data = log.photoData else { return }
            photoThumbnail = await Task.detached(priority: .userInitiated) {
                ImageProcessingService.displayImage(from: data, maxPixelSize: 600)
            }.value
        }
        .fullScreenCover(isPresented: $isShowingPhotoViewer) {
            if let data = log.photoData {
                PhotoViewerView(photoData: data)
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
    }
}
