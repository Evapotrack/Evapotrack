// StatusBadgeView.swift
// Evapotrack
//
// Color-coded capsule showing a plant's watering status at a glance.
// Uses the most recent log's date and average interval to determine status.

import SwiftUI

struct StatusBadgeView: View {
    let plant: Plant

    private var status: PlantStatus {
        let logs = plant.wateringLogs.sorted { $0.dateTime > $1.dateTime }
        guard let lastLog = logs.first else {
            return .neverWatered
        }

        // Use average intervalHours from logs, fall back to 3 days default
        let intervals = logs.compactMap(\.intervalHours)
        let avgIntervalDays: Double
        if !intervals.isEmpty {
            avgIntervalDays = (intervals.reduce(0, +) / Double(intervals.count)) / 24.0
        } else {
            avgIntervalDays = 3.0
        }

        return WateringCalculationService.plantStatus(
            lastWateredDate: lastLog.dateTime,
            recommendedIntervalDays: avgIntervalDays,
            dateProvider: SystemDateProvider()
        )
    }

    private var badgeText: String {
        switch status {
        case .neverWatered:
            return "New"
        case .healthy:
            return "Healthy"
        case .dueSoon(let days):
            return days == 0 ? "Due Today" : "Due Soon"
        case .overdue:
            return "Overdue"
        }
    }

    private var badgeColor: Color {
        switch status {
        case .neverWatered:
            return .evSlateGray
        case .healthy:
            return .green
        case .dueSoon:
            return .orange
        case .overdue:
            return .red
        }
    }

    var body: some View {
        Text(badgeText)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(badgeColor))
    }
}
