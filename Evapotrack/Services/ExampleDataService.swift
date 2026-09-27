// © 2026 Evapotrack. All rights reserved.
// ExampleDataService.swift
// Evapotrack
//
// Creates the "Try Example Data" grow shown from the empty grow list: two
// plants with six watering logs each, including temperature and humidity.
// The whole grow is saved in one step; if saving fails nothing is kept and
// the error is reported to the caller.

import Foundation
import SwiftData
import OSLog

@MainActor
final class ExampleDataService {

    private let modelContext: ModelContext
    private let save: SaveHandler

    init(modelContext: ModelContext, save: @escaping SaveHandler = { try $0.save() }) {
        self.modelContext = modelContext
        self.save = save
    }

    private struct ExampleWatering {
        let month: Int, day: Int, hour: Int, minute: Int
        let water: Double, runoff: Double
        let fahrenheit: Double, humidity: Double
    }

    func loadExampleGrow() throws {
        let grow = Grow(growName: Strings.exampleGrow)
        modelContext.insert(grow)

        // Capacities follow evapotrack.com/reference (1 gal soil ≈ 1.5 L,
        // 1 gal coco ≈ 2.3 L), measured from dry medium.
        let soilPlant = Plant(
            plantName: Strings.examplePlant,
            potSize: "Fabric 1 gal",
            mediumType: "soil",
            maxRetentionCapacity: 1.5,
            goalRunoffPercent: 15.0,
            grow: grow
        )
        insert(soilPlant, into: grow)
        addLogs([
            ExampleWatering(month: 2, day: 10, hour: 8, minute: 45, water: 1.50, runoff: 0.19, fahrenheit: 72, humidity: 48),
            ExampleWatering(month: 2, day: 12, hour: 9, minute: 24, water: 1.25, runoff: 0.32, fahrenheit: 78, humidity: 45),
            ExampleWatering(month: 2, day: 14, hour: 10, minute: 30, water: 1.25, runoff: 0.32, fahrenheit: 85, humidity: 53),
            ExampleWatering(month: 2, day: 16, hour: 18, minute: 36, water: 1.00, runoff: 0.32, fahrenheit: 91, humidity: 61),
            ExampleWatering(month: 2, day: 18, hour: 16, minute: 48, water: 0.89, runoff: 0.19, fahrenheit: 83, humidity: 57),
            ExampleWatering(month: 2, day: 21, hour: 11, minute: 6, water: 1.00, runoff: 0.10, fahrenheit: 69, humidity: 65)
        ], to: soilPlant)

        let cocoPlant = Plant(
            plantName: Strings.examplePlant2,
            potSize: "Plastic 1 gal",
            mediumType: "coco",
            maxRetentionCapacity: 2.3,
            goalRunoffPercent: 20.0,
            grow: grow
        )
        insert(cocoPlant, into: grow)
        addLogs([
            ExampleWatering(month: 2, day: 11, hour: 7, minute: 15, water: 1.80, runoff: 0.35, fahrenheit: 74, humidity: 52),
            ExampleWatering(month: 2, day: 13, hour: 8, minute: 50, water: 1.60, runoff: 0.28, fahrenheit: 76, humidity: 49),
            ExampleWatering(month: 2, day: 15, hour: 11, minute: 10, water: 1.70, runoff: 0.40, fahrenheit: 82, humidity: 55),
            ExampleWatering(month: 2, day: 17, hour: 17, minute: 22, water: 1.40, runoff: 0.25, fahrenheit: 88, humidity: 58),
            ExampleWatering(month: 2, day: 19, hour: 14, minute: 35, water: 1.50, runoff: 0.30, fahrenheit: 80, humidity: 62),
            ExampleWatering(month: 2, day: 22, hour: 9, minute: 45, water: 1.30, runoff: 0.15, fahrenheit: 71, humidity: 60)
        ], to: cocoPlant)

        try modelContext.saveOrRollback(using: save, action: "Load example data")
        Logger.services.info("Loaded example grow")
    }

    // MARK: - Private

    private func insert(_ plant: Plant, into grow: Grow) {
        modelContext.insert(plant)
        if !grow.plants.contains(where: { $0 === plant }) {
            grow.plants.append(plant)
        }
    }

    private func addLogs(_ waterings: [ExampleWatering], to plant: Plant) {
        let calendar = Calendar.current
        for watering in waterings {
            let components = DateComponents(
                year: 2026, month: watering.month, day: watering.day,
                hour: watering.hour, minute: watering.minute
            )
            let log = WateringLog(
                waterAdded: watering.water,
                runoffCollected: watering.runoff,
                dateTime: calendar.date(from: components) ?? Date(),
                temperatureCelsius: UnitConversionService.toCelsius(watering.fahrenheit, from: .fahrenheit),
                humidityPercent: watering.humidity
            )
            log.plant = plant
            modelContext.insert(log)
            if !plant.wateringLogs.contains(where: { $0 === log }) {
                plant.wateringLogs.append(log)
            }
        }
        WateringCalculationService.recalculateIntervalHours(for: plant.wateringLogs)
    }
}
