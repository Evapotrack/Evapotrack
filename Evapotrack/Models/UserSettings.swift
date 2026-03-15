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
    var appearanceMode: AppearanceMode = .dark
    var language: AppLanguage = .english

    static let `default` = UserSettings(
        waterUnit: .liters,
        temperatureUnit: .fahrenheit,
        appearanceMode: .dark,
        language: .english
    )

    // Custom decoder for backward compatibility:
    // - Missing key (pre-appearance data) → .dark
    // - Old "System" value (removed) → .dark
    // - "Light" / "Dark" → decode normally
    // - Missing language key (pre-localization) → .english
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        waterUnit = try container.decode(WaterUnit.self, forKey: .waterUnit)
        temperatureUnit = try container.decode(TemperatureUnit.self, forKey: .temperatureUnit)
        if let raw = try container.decodeIfPresent(String.self, forKey: .appearanceMode),
           let mode = AppearanceMode(rawValue: raw) {
            appearanceMode = mode
        } else {
            appearanceMode = .dark
        }
        if let raw = try container.decodeIfPresent(String.self, forKey: .language),
           let lang = AppLanguage(rawValue: raw) {
            language = lang
        } else {
            language = .english
        }
    }

    init(waterUnit: WaterUnit = .liters, temperatureUnit: TemperatureUnit = .fahrenheit, appearanceMode: AppearanceMode = .dark, language: AppLanguage = .english) {
        self.waterUnit = waterUnit
        self.temperatureUnit = temperatureUnit
        self.appearanceMode = appearanceMode
        self.language = language
    }
}

// MARK: - Language

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case english = "EN"
    case spanish = "ES"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

// MARK: - Appearance Mode

enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return Strings.dayMode
        case .dark:  return Strings.darkMode
        }
    }
}

// MARK: - Water Unit

enum WaterUnit: String, Codable, CaseIterable, Identifiable {
    case milliliters = "mL"
    case liters = "L"
    case gallons = "gal"

    var id: String { rawValue }

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

    var abbreviation: String { rawValue }

    /// Number of decimal places for display.
    var displayPrecision: Int { 1 }
}
