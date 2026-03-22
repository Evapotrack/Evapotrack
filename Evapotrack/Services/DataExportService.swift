// © 2026 Evapotrack. All rights reserved.
// DataExportService.swift
// Evapotrack
//
// Generates plain-text data exports for a Grow and its plants.
// Used by SettingsView to export grow data as a .txt file.

import SwiftUI
import UniformTypeIdentifiers

enum DataExportService {

    /// Generate a formatted plain-text export for a single grow.
    static func exportGrow(
        _ grow: Grow,
        waterUnit: WaterUnit,
        temperatureUnit: TemperatureUnit
    ) -> String {
        var lines: [String] = []
        let divider = String(repeating: "─", count: 60)

        lines.append("Evapotrack Data Export")
        lines.append("Generated: \(Date().formatted(date: .abbreviated, time: .shortened))")
        lines.append("")
        lines.append("Grow: \(grow.growName)")
        lines.append("Created: \(grow.createdAt.formatted(date: .abbreviated, time: .shortened))")
        lines.append("Plants: \(grow.plants.count)")
        lines.append("")
        lines.append(divider)

        let sortedPlants = grow.plants.sorted { $0.plantName.localizedCompare($1.plantName) == .orderedAscending }

        var totalLogs = 0

        for plant in sortedPlants {
            lines.append("")
            lines.append("Plant: \(plant.plantName)")
            lines.append("  Pot Size: \(plant.potSize)")
            lines.append("  Medium: \(plant.mediumType)")
            lines.append("  Max Retention: \(DisplayFormatter.water(plant.maxRetentionCapacity, unit: waterUnit))")
            lines.append("  Goal Runoff: \(DisplayFormatter.percent(plant.goalRunoffPercent))")
            lines.append("  Created: \(plant.createdAt.formatted(date: .abbreviated, time: .shortened))")
            lines.append("  Watering Logs: \(plant.wateringLogs.count)")

            let sortedLogs = plant.wateringLogs.sorted { $0.dateTime > $1.dateTime }
            totalLogs += sortedLogs.count

            if !sortedLogs.isEmpty {
                // Check if any log has env data to include those columns
                let hasTemp = sortedLogs.contains { $0.temperatureCelsius != nil }
                let hasHumidity = sortedLogs.contains { $0.humidityPercent != nil }

                lines.append("")
                var header = "  "
                header += "Date".padding(toLength: 22, withPad: " ", startingAt: 0)
                header += "Water Added".padding(toLength: 14, withPad: " ", startingAt: 0)
                header += "Runoff".padding(toLength: 12, withPad: " ", startingAt: 0)
                header += "Retained".padding(toLength: 12, withPad: " ", startingAt: 0)
                header += "Runoff%".padding(toLength: 10, withPad: " ", startingAt: 0)
                header += "Interval".padding(toLength: 10, withPad: " ", startingAt: 0)
                if hasTemp { header += "Temp".padding(toLength: 10, withPad: " ", startingAt: 0) }
                if hasHumidity { header += "Humidity" }
                lines.append(header)

                let headerWidth = hasTemp || hasHumidity ? 95 : 80
                lines.append("  " + String(repeating: "─", count: headerWidth))

                for log in sortedLogs {
                    let date = log.dateTime.formatted(date: .abbreviated, time: .shortened)
                    let water = DisplayFormatter.water(log.waterAdded, unit: waterUnit)
                    let runoff = DisplayFormatter.water(log.runoffCollected, unit: waterUnit)
                    let retained = DisplayFormatter.water(log.retained, unit: waterUnit)
                    let runoffPct = DisplayFormatter.percent(log.runoffPercent)
                    let interval = log.intervalHours.map { DisplayFormatter.intervalAdaptive($0) } ?? "—"

                    var line = "  "
                    line += date.padding(toLength: 22, withPad: " ", startingAt: 0)
                    line += water.padding(toLength: 14, withPad: " ", startingAt: 0)
                    line += runoff.padding(toLength: 12, withPad: " ", startingAt: 0)
                    line += retained.padding(toLength: 12, withPad: " ", startingAt: 0)
                    line += runoffPct.padding(toLength: 10, withPad: " ", startingAt: 0)
                    line += interval.padding(toLength: 10, withPad: " ", startingAt: 0)

                    if hasTemp {
                        let temp = log.temperatureCelsius.map {
                            DisplayFormatter.temperature($0, unit: temperatureUnit)
                        } ?? "—"
                        line += temp.padding(toLength: 10, withPad: " ", startingAt: 0)
                    }
                    if hasHumidity {
                        let humidity = log.humidityPercent.map {
                            DisplayFormatter.percent($0)
                        } ?? "—"
                        line += humidity
                    }

                    lines.append(line)
                }
            }

            lines.append("")
            lines.append(divider)
        }

        if sortedPlants.isEmpty {
            lines.append("")
            lines.append("No plants in this grow.")
            lines.append("")
            lines.append(divider)
        }

        // Summary
        lines.append("")
        lines.append("Total: \(sortedPlants.count) plant\(sortedPlants.count == 1 ? "" : "s"), \(totalLogs) watering log\(totalLogs == 1 ? "" : "s")")

        return lines.joined(separator: "\n")
    }
}

// MARK: - FileDocument for .fileExporter

struct GrowExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        text = String(data: configuration.file.regularFileContents ?? Data(), encoding: .utf8) ?? ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}
