// AppConstants.swift
// Evapotrack
//
// Central location for app-wide constants: validation bounds,
// algorithm parameters, and default configuration values.

import Foundation

enum AppConstants {

    // MARK: - General

    static let appName = "Evapotrack"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

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
    static let minimumIntervalDays = 1.0
    static let maximumIntervalDays = 60.0

    // MARK: - Algorithm

    /// Minimum number of watering logs before history-based blending kicks in.
    static let minimumLogsForBlending = 3

    /// Formula weight when blending with actual history.
    static let formulaWeight = 0.4

    /// History weight when blending with actual history.
    static let historyWeight = 0.6

    /// Blending weights must sum to 1.0 — verified at the call site.
    static let blendingWeightSum = formulaWeight + historyWeight

    /// Target runoff percentage used by the Next water recommendation algorithm.
    static let targetRunoffPercent = 15.0

    /// Maximum Capacity % displayed. Caps at 105% to allow minor
    /// fluctuations in retention while preventing unrealistic values.
    static let maxCapacityPercent = 105.0

    /// Maximum retained volume as a factor of Max Retention Capacity.
    /// 1.05 = 105% — matches the Capacity % display cap.
    static let maxRetainedFactor = 1.05

    // MARK: - UserDefaults Keys

    static let userSettingsKey = "userSettings"
}
