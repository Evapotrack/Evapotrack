// StatusBadgeView.swift
// Evapotrack
//
// Capsule badge showing plant watering status with color coding.

import SwiftUI

struct StatusBadgeView: View {
    let status: PlantStatus

    var body: some View {
        Text(label)
            .font(.footnote)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch status {
        case .neverWatered:
            return "New"
        case .healthy(let days):
            return "\(days)d left"
        case .dueSoon(let days):
            return days == 0 ? "Due today" : "Due in \(days)d"
        case .overdue(let days):
            return "\(days)d overdue"
        }
    }

    private var color: Color {
        switch status {
        case .neverWatered: return .gray
        case .healthy:      return .green
        case .dueSoon:      return .orange
        case .overdue:      return .red
        }
    }
}
