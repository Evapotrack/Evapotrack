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
            VStack(alignment: .leading, spacing: 4) {
                Text(grow.growName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.evPrimaryText)
                HStack(spacing: 12) {
                    Text(grow.createdAt.shortFormatted)
                        .font(.callout)
                        .foregroundStyle(Color.evSecondaryText)
                    Text("\(grow.plants.count) plant\(grow.plants.count == 1 ? "" : "s")")
                        .font(.callout)
                        .foregroundStyle(Color.evDeepNavy)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.evFrostBlue.opacity(0.3))
                        )
                }
            }
        }
        .padding(.vertical, 6)
    }
}
