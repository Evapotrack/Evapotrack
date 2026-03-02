// PlantRowView.swift
// Evapotrack
//
// A single row in the plant list.
// Shows a left-side circular selection indicator and plantName only.
// The selection circle is for deletion; tapping the name navigates.

import SwiftUI

struct PlantRowView: View {
    let plant: Plant
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
            .accessibilityLabel(isSelected ? "Deselect \(plant.plantName)" : "Select \(plant.plantName)")

            // Plant info
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.plantName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.evDeepNavy)

                HStack(spacing: 4) {
                    if !plant.potSize.isEmpty {
                        Text(plant.potSize)
                    }
                    if !plant.potSize.isEmpty && !plant.mediumType.isEmpty {
                        Text("·")
                    }
                    if !plant.mediumType.isEmpty {
                        Text(plant.mediumType)
                    }
                    if !plant.potSize.isEmpty || !plant.mediumType.isEmpty {
                        Text("·")
                    }
                    Text("\(plant.wateringLogs.count) \(plant.wateringLogs.count == 1 ? "log" : "logs")")
                }
                .font(.subheadline)
                .foregroundStyle(Color.evSecondaryText)
            }
        }
        .padding(.vertical, 6)
    }
}
