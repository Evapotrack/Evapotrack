// © 2026 Evapotrack. All rights reserved.
// DisplayFormatter.swift
// Evapotrack
//
// Centralized display-time formatting. All rounding happens here
// and only here. Internal stored values are never altered.
//
// Precision rules:
//   mL:  0 decimals       °C:  1 decimal
//   L:   2 decimals       °F:  1 decimal
//   gal: 2 decimals       %:   1 decimal
//   Interval ≥24h: Xd Yh, <24h: 1 decimal hours, <1h: 0 decimal min/sec

import Foundation

enum DisplayFormatter {

    // MARK: - Water

    /// Format an internal liters value for display in the user's chosen unit.
    static func water(_ liters: Double, unit: WaterUnit) -> String {
        let converted = UnitConversionService.fromLiters(liters, to: unit)
        return "\(formatNumber(converted, decimals: unit.displayPrecision)) \(unit.abbreviation)"
    }

    // MARK: - Temperature

    /// Format an internal Celsius value for display in the user's chosen unit.
    static func temperature(_ celsius: Double, unit: TemperatureUnit) -> String {
        let converted = UnitConversionService.fromCelsius(celsius, to: unit)
        return "\(formatNumber(converted, decimals: unit.displayPrecision)) \(unit.abbreviation)"
    }

    // MARK: - Percentage

    /// Format a percentage value (already 0–100) for display. 1 decimal.
    static func percent(_ value: Double) -> String {
        "\(formatNumber(value, decimals: 1))%"
    }

    // MARK: - Interval

    /// Format interval as days+hours if ≥ 24h, hours if ≥ 1h, minutes if ≥ 1min, else seconds.
    /// Never displays less than 1 second.
    static func intervalAdaptive(_ hours: Double) -> String {
        if hours >= 24.0 {
            let wholeDays = Int(hours / 24.0)
            let remainingHours = Int(hours.truncatingRemainder(dividingBy: 24.0))
            if remainingHours > 0 {
                return "\(wholeDays)d \(remainingHours)h"
            }
            return "\(wholeDays)d"
        } else if hours >= 1.0 {
            return "\(formatNumber(hours, decimals: 1)) h"
        } else {
            let minutes = hours * 60.0
            if minutes >= 1.0 {
                return "\(formatNumber(minutes, decimals: 0)) min"
            } else {
                let seconds = max(1.0, hours * 3600.0)
                return "\(formatNumber(seconds, decimals: 0)) sec"
            }
        }
    }

    // MARK: - Private

    private static func formatNumber(_ value: Double, decimals: Int) -> String {
        let clamped = max(0, min(decimals, 10))
        return String(format: "%.\(clamped)f", value)
    }
}
