// © 2026 Evapotrack. All rights reserved.
// AppConstants.swift
// Evapotrack
//
// Central location for app-wide constants: validation bounds,
// algorithm parameters, and default configuration values.

import Foundation

enum AppConstants {

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
    // MARK: - Photos

    /// Longest edge of a stored watering-log photo, in pixels.
    static let maxPhotoDimension = 2048

    /// Maximum stored size of a watering-log photo, in bytes (~800 KB).
    static let maxPhotoBytes = 800_000

    /// Initial JPEG compression quality; reduced stepwise until under maxPhotoBytes.
    static let photoJPEGQuality = 0.7

    // MARK: - Algorithm

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
