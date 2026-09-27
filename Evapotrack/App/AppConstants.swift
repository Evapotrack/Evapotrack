// © 2026 Evapotrack. All rights reserved.
// AppConstants.swift
// Evapotrack
//
// Central location for app-wide constants: validation bounds,
// algorithm parameters, and default configuration values.

import Foundation

nonisolated enum AppConstants {

    // MARK: - Validation Bounds

    static let maxGrowNameLength = 50
    static let maxPlantNameLength = 50
    static let maxPotSizeLength = 30
    static let maxMediumTypeLength = 30
    /// Maximum grows a user can create. Keeps SwiftData performant
    /// on older devices while being generous for serious growers
    /// (30 grows × 25 plants = 750 plants max).
    static let maxGrowCount = 30

    /// Maximum plants per grow. Prevents excessively long lists and
    /// keeps relationship arrays manageable for interval recalculation.
    static let maxPlantsPerGrow = 25

    /// Hard cap on total plants across all grows.
    /// maxGrowCount × maxPlantsPerGrow = 750.
    static let maxTotalPlants = 750
    static let maxNumericInputLength = 10
    static let maxRetentionCapacityRange: ClosedRange<Double> = 0.001...100.0
    static let waterAddedRange: ClosedRange<Double> = 0.001...100.0
    static let humidityRange: ClosedRange<Double> = 0.0...100.0
    static let temperatureRangeCelsius: ClosedRange<Double> = -50.0...60.0
    // MARK: - Algorithm

    /// Default goal runoff percentage for new plants.
    static let targetRunoffPercent = 15.0

    /// Goal runoff percentages a grower can set, and the range the
    /// recommendation engine uses. Below 5% the runoff is too small to measure
    /// reliably with a collection tray; above 50% more water would drain than
    /// stay in the pot, and Next would exceed twice the plant's uptake.
    /// Drain-to-waste practice is typically 10–30%.
    static let goalRunoffPercentRange: ClosedRange<Double> = 5.0...50.0

    /// A watering that retains more than this factor × Max Retention Capacity
    /// asks the grower to confirm (5% tolerance for measuring error). It is
    /// never rejected: the capacity itself may be set too low.
    static let retainedConfirmationFactor = 1.05

    // MARK: - UserDefaults Keys

    static let userSettingsKey = "userSettings"
}
