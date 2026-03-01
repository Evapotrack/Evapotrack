// UserSettings.swift
// Evapotrack
//
// Persisted user preferences: water and temperature display units.
// Stored in UserDefaults via JSON encoding.
// Display units control formatting only — stored values always
// use internal units (liters, Celsius) and are never rounded.

import Foundation

struct UserSettings: Codable, Equatable {
    var waterUnit: WaterUnit
    var temperatureUnit: TemperatureUnit
    var appearanceMode: AppearanceMode = .light

    static let `default` = UserSettings(
        waterUnit: .liters,
        temperatureUnit: .fahrenheit,
        appearanceMode: .light
    )

    // Custom decoder for backward compatibility:
    // - Missing key (pre-appearance data) → .light
    // - Old "System" value (removed) → .light
    // - "Light" / "Dark" → decode normally
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        waterUnit = try container.decode(WaterUnit.self, forKey: .waterUnit)
        temperatureUnit = try container.decode(TemperatureUnit.self, forKey: .temperatureUnit)
        if let raw = try container.decodeIfPresent(String.self, forKey: .appearanceMode),
           let mode = AppearanceMode(rawValue: raw) {
            appearanceMode = mode
        } else {
            appearanceMode = .light
        }
    }

    init(waterUnit: WaterUnit = .liters, temperatureUnit: TemperatureUnit = .fahrenheit, appearanceMode: AppearanceMode = .light) {
        self.waterUnit = waterUnit
        self.temperatureUnit = temperatureUnit
        self.appearanceMode = appearanceMode
    }
}

// MARK: - Appearance Mode

enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Day"
        case .dark:  return "Dark"
        }
    }
}

// MARK: - Water Unit

enum WaterUnit: String, Codable, CaseIterable, Identifiable {
    case milliliters = "mL"
    case liters = "L"
    case gallons = "gal"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .milliliters: return "Milliliters"
        case .liters:      return "Liters"
        case .gallons:     return "Gallons"
        }
    }

    var abbreviation: String { rawValue }

    /// Number of decimal places for display.
    var displayPrecision: Int {
        switch self {
        case .milliliters: return 0
        case .liters:      return 2
        case .gallons:     return 2
        }
    }
}

// MARK: - Temperature Unit

enum TemperatureUnit: String, Codable, CaseIterable, Identifiable {
    case celsius = "°C"
    case fahrenheit = "°F"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .celsius:    return "Celsius"
        case .fahrenheit: return "Fahrenheit"
        }
    }

    var abbreviation: String { rawValue }

    /// Number of decimal places for display.
    var displayPrecision: Int { 1 }
}
