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

            if !sortedLogs.isEmpty {
                lines.append("")
                lines.append("  Date                  Water Added   Runoff      Retained    Runoff%   Interval")
                lines.append("  " + String(repeating: "─", count: 85))

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
                    line += interval

                    if let temp = log.temperatureCelsius {
                        line += "  \(DisplayFormatter.temperature(temp, unit: temperatureUnit))"
                    }
                    if let humidity = log.humidityPercent {
                        line += "  \(DisplayFormatter.percent(humidity)) RH"
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
