// © 2026 Evapotrack. All rights reserved.
// DataExportTests.swift
// EvapotrackDevTests
//
// Snapshot tests for the plain-text grow export. The expected lines pin the
// export format exactly (column widths, padding, rounding, sorting), so any
// change to it is deliberate and visible in review. The no-photo snapshot
// was written before the photo column existed and still passes unchanged.

import XCTest
import SwiftData
@testable import EvapotrackDev

@MainActor
final class DataExportTests: XCTestCase {

    // MARK: - Fixture

    private static let utc = TimeZone(identifier: "UTC")!

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = utc
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    private static func date(_ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        return calendar.date(from: DateComponents(year: 2026, month: 3, day: day, hour: hour, minute: minute))!
    }

    /// A grow with three plants: one without logs, one whose logs include
    /// temperature and humidity, and one without either.
    private func makeGrow(in context: ModelContext, photoOnFirstBasilLog: UUID? = nil) -> Grow {
        let grow = Grow(growName: "Tent A", createdAt: Self.date(1, 0, 0))
        context.insert(grow)

        let basil = addPlant("Basil", pot: "Fabric 3 gal", medium: "soil", capacity: 1.5, goal: 15, created: Self.date(1, 0, 5), to: grow, in: context)
        addLog(WateringLog(waterAdded: 1.0, runoffCollected: 0.2, dateTime: Self.date(2, 8, 0), temperatureCelsius: 22.5, humidityPercent: 60, photoFileID: photoOnFirstBasilLog), to: basil, in: context)
        addLog(WateringLog(waterAdded: 1.2, runoffCollected: 0.3, dateTime: Self.date(4, 10, 15), intervalHours: 50.25), to: basil, in: context)

        _ = addPlant("Aloe", pot: "Plastic 1 gal", medium: "coco", capacity: 0.8, goal: 20, created: Self.date(1, 0, 10), to: grow, in: context)

        let cactus = addPlant("Cactus", pot: "Clay 6 in", medium: "gritty mix", capacity: 0.4, goal: 10, created: Self.date(1, 0, 15), to: grow, in: context)
        addLog(WateringLog(waterAdded: 0.5, runoffCollected: 0.0, dateTime: Self.date(3, 9, 0)), to: cactus, in: context)

        return grow
    }

    @discardableResult
    private func addPlant(
        _ name: String, pot: String, medium: String, capacity: Double, goal: Double,
        created: Date, to grow: Grow, in context: ModelContext
    ) -> Plant {
        let plant = Plant(plantName: name, potSize: pot, mediumType: medium, maxRetentionCapacity: capacity, goalRunoffPercent: goal, createdAt: created, grow: grow)
        context.insert(plant)
        if !grow.plants.contains(where: { $0 === plant }) {
            grow.plants.append(plant)
        }
        return plant
    }

    private func addLog(_ log: WateringLog, to plant: Plant, in context: ModelContext) {
        log.plant = plant
        context.insert(log)
        if !plant.wateringLogs.contains(where: { $0 === log }) {
            plant.wateringLogs.append(log)
        }
    }

    private func export(_ grow: Grow) -> [String] {
        DataExportService.exportGrow(
            grow,
            waterUnit: .liters,
            temperatureUnit: .celsius,
            now: Self.date(10, 12, 0),
            formatDate: Self.formatter.string(from:)
        ).components(separatedBy: "\n")
    }

    private func assertLines(_ actual: [String], _ expected: [String], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(actual.count, expected.count, "line count", file: file, line: line)
        for (index, pair) in zip(actual, expected).enumerated() where pair.0 != pair.1 {
            XCTFail("line \(index + 1):\n  got      \"\(pair.0)\"\n  expected \"\(pair.1)\"", file: file, line: line)
        }
    }

    // MARK: - Format

    /// The export format before photos were added. Written before any format
    /// change; a grow without photos must still export exactly like this.
    func test_export_withoutPhotos_matchesEstablishedFormat() throws {
        let context = ModelContext(try PersistenceController.makeInMemoryContainer())
        let grow = makeGrow(in: context)

        assertLines(export(grow), [
            "Evapotrack Data Export",
            "Generated: 2026-03-10 12:00",
            "",
            "Grow: Tent A",
            "Created: 2026-03-01 00:00",
            "Plants: 3",
            "",
            "────────────────────────────────────────────────────────────",
            "",
            "Plant: Aloe",
            "  Pot Size: Plastic 1 gal",
            "  Medium: coco",
            "  Max Retention: 0.80 L",
            "  Goal Runoff: 20.0%",
            "  Created: 2026-03-01 00:10",
            "  Watering Logs: 0",
            "",
            "────────────────────────────────────────────────────────────",
            "",
            "Plant: Basil",
            "  Pot Size: Fabric 3 gal",
            "  Medium: soil",
            "  Max Retention: 1.50 L",
            "  Goal Runoff: 15.0%",
            "  Created: 2026-03-01 00:05",
            "  Watering Logs: 2",
            "",
            "  Date                  Water Added   Runoff      Retained    Runoff%   Interval  Temp      Humidity",
            "  ───────────────────────────────────────────────────────────────────────────────────────────────",
            "  2026-03-04 10:15      1.20 L        0.30 L      0.90 L      25.0%     2d 2h     —         —",
            "  2026-03-02 08:00      1.00 L        0.20 L      0.80 L      20.0%     —         22.5 °C   60.0%",
            "",
            "────────────────────────────────────────────────────────────",
            "",
            "Plant: Cactus",
            "  Pot Size: Clay 6 in",
            "  Medium: gritty mix",
            "  Max Retention: 0.40 L",
            "  Goal Runoff: 10.0%",
            "  Created: 2026-03-01 00:15",
            "  Watering Logs: 1",
            "",
            "  Date                  Water Added   Runoff      Retained    Runoff%   Interval  ",
            "  ────────────────────────────────────────────────────────────────────────────────",
            "  2026-03-03 09:00      0.50 L        0.00 L      0.50 L      0.0%      —         ",
            "",
            "────────────────────────────────────────────────────────────",
            "",
            "Total: 3 plants, 3 watering logs",
        ])
    }

    /// A plant with photos gets a Photo column; the export ends with a note
    /// that photos are not included. Plants without photos are unchanged.
    func test_export_withPhoto_addsPhotoColumnAndNote() throws {
        let context = ModelContext(try PersistenceController.makeInMemoryContainer())
        let grow = makeGrow(in: context, photoOnFirstBasilLog: UUID())

        assertLines(export(grow), [
            "Evapotrack Data Export",
            "Generated: 2026-03-10 12:00",
            "",
            "Grow: Tent A",
            "Created: 2026-03-01 00:00",
            "Plants: 3",
            "",
            "────────────────────────────────────────────────────────────",
            "",
            "Plant: Aloe",
            "  Pot Size: Plastic 1 gal",
            "  Medium: coco",
            "  Max Retention: 0.80 L",
            "  Goal Runoff: 20.0%",
            "  Created: 2026-03-01 00:10",
            "  Watering Logs: 0",
            "",
            "────────────────────────────────────────────────────────────",
            "",
            "Plant: Basil",
            "  Pot Size: Fabric 3 gal",
            "  Medium: soil",
            "  Max Retention: 1.50 L",
            "  Goal Runoff: 15.0%",
            "  Created: 2026-03-01 00:05",
            "  Watering Logs: 2",
            "",
            "  Date                  Water Added   Runoff      Retained    Runoff%   Interval  Temp      Humidity  Photo",
            "  ─────────────────────────────────────────────────────────────────────────────────────────────────────────",
            "  2026-03-04 10:15      1.20 L        0.30 L      0.90 L      25.0%     2d 2h     —         —         —",
            "  2026-03-02 08:00      1.00 L        0.20 L      0.80 L      20.0%     —         22.5 °C   60.0%     Yes",
            "",
            "────────────────────────────────────────────────────────────",
            "",
            "Plant: Cactus",
            "  Pot Size: Clay 6 in",
            "  Medium: gritty mix",
            "  Max Retention: 0.40 L",
            "  Goal Runoff: 10.0%",
            "  Created: 2026-03-01 00:15",
            "  Watering Logs: 1",
            "",
            "  Date                  Water Added   Runoff      Retained    Runoff%   Interval  ",
            "  ────────────────────────────────────────────────────────────────────────────────",
            "  2026-03-03 09:00      0.50 L        0.00 L      0.50 L      0.0%      —         ",
            "",
            "────────────────────────────────────────────────────────────",
            "",
            "Total: 3 plants, 3 watering logs",
            "",
            "Photos: 1 watering log has a photo. Photos stay on this device and are not included in this export.",
        ])
    }

    func test_export_emptyGrow() throws {
        let context = ModelContext(try PersistenceController.makeInMemoryContainer())
        let grow = Grow(growName: "Empty", createdAt: Self.date(1, 0, 0))
        context.insert(grow)

        assertLines(export(grow), [
            "Evapotrack Data Export",
            "Generated: 2026-03-10 12:00",
            "",
            "Grow: Empty",
            "Created: 2026-03-01 00:00",
            "Plants: 0",
            "",
            "────────────────────────────────────────────────────────────",
            "",
            "No plants in this grow.",
            "",
            "────────────────────────────────────────────────────────────",
            "",
            "Total: 0 plants, 0 watering logs",
        ])
    }
}
