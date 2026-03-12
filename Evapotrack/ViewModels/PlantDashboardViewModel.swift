// PlantDashboardViewModel.swift
// Evapotrack
//
// State and actions for the PlantDashboard screen.
// Shows summary, insights, and history for a single plant.
// All calculations use internal units (liters, Celsius).
// No editing of plants or logs is allowed.

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class PlantDashboardViewModel {

    // MARK: - State

    let plant: Plant
    var wateringLogs: [WateringLog] = []
    var isShowingAddWatering = false
    var isShowingSettings = false
    var deleteError: String?

    // MARK: - Dependencies

    private var logService: WateringLogService?
    private let dateProvider: DateProviding

    init(plant: Plant, dateProvider: DateProviding = SystemDateProvider()) {
        self.plant = plant
        self.dateProvider = dateProvider
    }

    func configure(modelContext: ModelContext) {
        guard logService == nil else { return }
        self.logService = WateringLogService(modelContext: modelContext)
    }

    // MARK: - Summary Computed

    /// The most recent watering log (logs are sorted newest-first).
    var lastLog: WateringLog? {
        wateringLogs.first
    }

    // MARK: - Insights Computed

    /// Average retained water across all logs, in liters.
    var averageRetained: Double? {
        guard !wateringLogs.isEmpty else { return nil }
        return wateringLogs.map(\.retained).reduce(0, +) / Double(wateringLogs.count)
    }

    /// Recommended next water amount and estimated runoff, in liters.
    var nextRecommendation: NextWaterRecommendation? {
        guard let last = lastLog, let avgRet = averageRetained else { return nil }
        return WateringCalculationService.computeNextWaterRecommendation(
            lastLog: last,
            averageRetained: avgRet,
            maxRetentionCapacity: plant.maxRetentionCapacity,
            goalRunoffPercent: plant.goalRunoffPercent
        )
    }

    // MARK: - Actions

    func loadData() {
        guard let service = logService else { return }
        wateringLogs = service.fetchLogs(for: plant)
    }

    func deleteLog(_ log: WateringLog) {
        guard let service = logService else { return }
        do {
            try service.deleteLog(log)
            loadData()
        } catch {
            deleteError = "Failed to delete log. Please try again."
        }
    }
}
