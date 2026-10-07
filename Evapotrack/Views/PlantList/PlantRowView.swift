// © 2026 Evapotrack. All rights reserved.
// PlantRowView.swift
// Evapotrack
//
// A single row in the plant list.
// Shows a left-side circular selection indicator and plantName.
// The selection circle is for deletion; tapping the name navigates.

import SwiftUI

struct PlantRowView: View {
    let plant: Plant
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
            .accessibilityLabel(isSelected ? Strings.deselectItem(plant.plantName) : Strings.selectItem(plant.plantName))

            // Plant info and status
            Text(plant.plantName)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.evDeepNavy)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()
        }
        .padding(.vertical, 8)
    }
}
