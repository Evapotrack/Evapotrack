// © 2026 Evapotrack. All rights reserved.
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
        HStack(spacing: 2) {
            // Left-side circular selection indicator (44 pt tap target; the
            // spacing is reduced so the symbol and text stay where they were)
            Button {
                onToggleSelection()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? Color.evPrimaryBlue : Color.evSlateGray)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityLabel(isSelected ? Strings.deselectItem(grow.growName) : Strings.selectItem(grow.growName))

            // Grow info
            VStack(alignment: .leading, spacing: 6) {
                Text(grow.growName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.evDeepNavy)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 16) {
                    Label {
                        Text(Strings.plantCount(grow.plants.count))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.evPrimaryBlue)
                    } icon: {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(Color.evPrimaryBlue)
                    }
                    .font(.callout)

                    Label {
                        Text(grow.createdAt.shortFormatted)
                            .foregroundStyle(Color.evSecondaryText)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color.evSecondaryText)
                    }
                    .font(.callout)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
