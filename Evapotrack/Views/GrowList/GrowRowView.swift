// GrowRowView.swift
// Evapotrack
//
// A single row in the grow list.
// Shows a left-side circular selection indicator, grow name,
// created date, and plant count.

import SwiftUI

struct GrowRowView: View {
    let grow: Grow
    let isSelected: Bool
    let onToggleSelection: () -> Void

    var body: some View {
        HStack(spacing: 12) {
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
            .accessibilityLabel(isSelected ? "Deselect \(grow.growName)" : "Select \(grow.growName)")

            // Grow info
            VStack(alignment: .leading, spacing: 6) {
                Text(grow.growName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.evDeepNavy)

                HStack(spacing: 16) {
                    Label {
                        Text("\(grow.plants.count)")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.evPrimaryBlue)
                    } icon: {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(Color.evPrimaryBlue)
                    }
                    .font(.subheadline)

                    Label {
                        Text(grow.createdAt.shortFormatted)
                            .foregroundStyle(Color.evSecondaryText)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color.evSecondaryText)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
