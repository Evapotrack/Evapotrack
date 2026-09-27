// © 2026 Evapotrack. All rights reserved.
// PlantDashboardViewModel.swift
// Evapotrack
//
// State and actions for the PlantDashboard screen.
// Shows summary, insights, and history for a single plant.
// All calculations use internal units (liters, Celsius).
// Watering logs are never edited; the recommendation is recomputed
// from the current logs every time it is read.

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class PlantDashboardViewModel {

    // MARK: - State

    nonisolated(unsafe) let plant: Plant
    var wateringLogs: [WateringLog] = []
    var isShowingAddWatering = false
    var isShowingSettings = false
    var deleteError: String?

    // MARK: - Dependencies

    private var logService: WateringLogService?
    private let dateProvider: DateProviding

    nonisolated init(plant: Plant, dateProvider: DateProviding = SystemDateProvider()) {
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

    /// Next-watering recommendation computed from this plant's full history.
    var recommendation: RecommendationOutcome {
        RecommendationEngine.recommend(
            observations: wateringLogs.map(\.observation),
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
            deleteError = Strings.failedDeleteLog
        }
    }
}

// MARK: - Recommendation Input

private extension WateringLog {
    /// The measured values the recommendation engine works from.
    var observation: WateringObservation {
        WateringObservation(waterAdded: waterAdded, runoff: runoffCollected, date: dateTime)
    }
}
