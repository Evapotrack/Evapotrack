// UnitConversionService.swift
// Evapotrack
//
// Pure, stateless, bidirectional unit conversions.
// All conversions start from internal units (liters, Celsius).
// Conversions never round — rounding is display-only.
// All functions are deterministic and free of side effects.

import Foundation

enum UnitConversionService {

    // MARK: - Water Constants

    private static let millilitersPerLiter = 1000.0
    private static let litersPerGallon = 3.785411784

    // MARK: - Water: Internal (liters) → Display

    /// Convert liters to the specified display unit. Pure, no rounding.
    static func fromLiters(_ liters: Double, to unit: WaterUnit) -> Double {
        switch unit {
        case .milliliters: return liters * millilitersPerLiter
        case .liters:      return liters
        case .gallons:     return liters / litersPerGallon
        }
    }

    /// Convert from display unit back to liters. Pure, no rounding.
    static func toLiters(_ value: Double, from unit: WaterUnit) -> Double {
        switch unit {
        case .milliliters: return value / millilitersPerLiter
        case .liters:      return value
        case .gallons:     return value * litersPerGallon
        }
    }

    // MARK: - Temperature: Internal (Celsius) → Display

    /// Convert Celsius to the specified display unit. Pure, no rounding.
    static func fromCelsius(_ celsius: Double, to unit: TemperatureUnit) -> Double {
        switch unit {
        case .celsius:    return celsius
        case .fahrenheit: return celsius * 9.0 / 5.0 + 32.0
        }
    }

    /// Convert from display unit back to Celsius. Pure, no rounding.
    static func toCelsius(_ value: Double, from unit: TemperatureUnit) -> Double {
        switch unit {
        case .celsius:    return value
        case .fahrenheit: return (value - 32.0) * 5.0 / 9.0
        }
    }
}
