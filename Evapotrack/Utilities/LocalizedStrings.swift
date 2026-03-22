// © 2026 Evapotrack. All rights reserved.
// LocalizedStrings.swift
// Evapotrack
//
// Centralized EN/ES string pairs for in-app language switching.
// Every user-facing string is a computed property on the Strings enum.
// The active language is synced from SettingsViewModel on load/save.

import Foundation

enum Strings {
    nonisolated(unsafe) static var current: AppLanguage = .english
    private static var es: Bool { current == .spanish }

    // MARK: - Navigation Titles

    static var myGrows: String { es ? "Mis Cultivos" : "My Grows" }
    static var addGrow: String { es ? "Agregar Cultivo" : "Add Grow" }
    static var addPlant: String { es ? "Agregar Planta" : "Add Plant" }
    static var addWateringEvent: String { es ? "Agregar Evento de Riego" : "Add Watering Event" }
    static var settings: String { es ? "Configuración" : "Settings" }
    static var howTo: String { es ? "Cómo Usar" : "How To" }

    // MARK: - Section Headers

    static var grows: String { es ? "Cultivos" : "Grows" }
    static var plantList: String { es ? "Lista de plantas" : "Plant list" }
    static var displayUnits: String { es ? "Unidades de Visualización" : "Display Units" }
    static var theme: String { es ? "Tema" : "Theme" }
    static var downloadData: String { es ? "Descargar Datos" : "Download Data" }
    static var plantInfo: String { es ? "Información de la Planta" : "Plant Info" }
    static var growInfo: String { es ? "Información del Cultivo" : "Grow Info" }
    static var summary: String { es ? "Resumen" : "Summary" }
    static var insights: String { es ? "Análisis" : "Insights" }
    static var history: String { es ? "Historial" : "History" }
    static var water: String { es ? "Agua" : "Water" }
    static var dateAndTime: String { es ? "Fecha y Hora" : "Date & Time" }
    static var environment: String { es ? "Ambiente" : "Environment" }
    static var capacity: String { es ? "Capacidad" : "Capacity" }
    static var timestamp: String { es ? "Marca de Tiempo" : "Timestamp" }
    static var language: String { es ? "Idioma" : "Language" }
    static var goalRunoffSection: String { es ? "% de Drenaje Objetivo" : "Goal Runoff %" }

    // MARK: - Buttons

    static var save: String { es ? "Guardar" : "Save" }
    static var cancel: String { es ? "Cancelar" : "Cancel" }
    static var done: String { es ? "Listo" : "Done" }
    static var delete: String { es ? "Eliminar" : "Delete" }
    static var close: String { es ? "Cerrar" : "Close" }
    static var calculate: String { es ? "Calcular" : "Calculate" }
    static var clear: String { es ? "Limpiar" : "Clear" }
    static var resetSettings: String { es ? "Restablecer Configuración" : "Reset Settings" }
    static var saved: String { es ? "Guardado" : "Saved" }
    static var ok: String { "OK" }

    // MARK: - Labels

    static var waterUnit: String { es ? "Unidad de Agua" : "Water Unit" }
    static var temperatureUnit: String { es ? "Unidad de Temperatura" : "Temperature Unit" }
    static var appearance: String { es ? "Apariencia" : "Appearance" }
    static var lastEvent: String { es ? "Último Evento" : "Last Event" }
    static var interval: String { es ? "Intervalo" : "Interval" }
    static var retained: String { es ? "Retenido" : "Retained" }
    static var capacityLabel: String { es ? "Capacidad" : "Capacity" }
    static var average: String { es ? "Promedio" : "Average" }
    static var next: String { es ? "Siguiente" : "Next" }
    static var viewAllLogs: String { es ? "Ver Todos los Registros" : "View All Logs" }
    static var date: String { es ? "Fecha" : "Date" }
    static var time: String { es ? "Hora" : "Time" }
    static var created: String { es ? "Creado" : "Created" }
    static var today: String { es ? "Hoy" : "Today" }
    static var yesterday: String { es ? "Ayer" : "Yesterday" }
    static var calculator: String { es ? "Calculadora" : "Calculator" }
    static var permanently: String { es ? "permanentemente" : "permanently" }

    // MARK: - Field Labels

    static var waterAdded: String { es ? "Agua Agregada" : "Water Added" }
    static var runoffCollected: String { es ? "Drenaje Recolectado" : "Runoff Collected" }
    static var runoffPercent: String { es ? "% de Drenaje" : "Runoff %" }
    static var capacityPercent: String { es ? "% de Capacidad" : "Capacity %" }
    static var temperature: String { es ? "Temperatura" : "Temperature" }
    static var humidity: String { es ? "Humedad" : "Humidity" }
    static var added: String { es ? " agr." : " added" }
    static var ret: String { es ? " ret" : " ret" }

    // MARK: - Placeholders

    static var growName: String { es ? "Nombre del Cultivo" : "Grow Name" }
    static var plantName: String { es ? "Nombre de la Planta" : "Plant Name" }
    static var potSizePlaceholder: String { es ? "Tamaño (ej. Tela 3 gal)" : "Pot Size (e.g. Fabric 3 gal)" }
    static var mediumTypePlaceholder: String { es ? "Tipo de Medio (ej. tierra, perlita)" : "Medium Type (e.g. soil, perlite)" }
    static var goalRunoffPlaceholder: String { es ? "Ejemplo: 15%" : "Example: 15%" }

    // MARK: - Dynamic Field Labels (with unit interpolation)

    static func waterAddedField(_ unit: String) -> String {
        es ? "Agua Agregada (\(unit))" : "Water Added (\(unit))"
    }
    static func runoffCollectedField(_ unit: String) -> String {
        es ? "Drenaje Recolectado (\(unit))" : "Runoff Collected (\(unit))"
    }
    static func maxRetentionField(_ unit: String) -> String {
        es ? "Capacidad Máx. de Retención (\(unit))" : "Max Retention Capacity (\(unit))"
    }
    static func temperatureField(_ unit: String) -> String {
        es ? "Temperatura (\(unit), opcional)" : "Temperature (\(unit), optional)"
    }
    static var humidityField: String {
        es ? "Humedad (%, opcional)" : "Humidity (%, optional)"
    }

    // MARK: - Appearance Mode

    static var dayMode: String { es ? "Día" : "Day" }
    static var darkMode: String { es ? "Oscuro" : "Dark" }

    // MARK: - Empty States

    static var noGrowsCreated: String { es ? "Sin Cultivos" : "No Grows Created" }
    static var tapToCreateGrow: String { es ? "para crear tu primer cultivo." : "to create your first grow." }
    static var tap: String { es ? "Toca" : "Tap" }
    static var noPlantsYet: String { es ? "Sin Plantas" : "No Plants Yet" }
    static var tapToAddPlant: String { es ? "para agregar tu primera planta." : "to add your first plant." }
    static var noWateringLogsYet: String { es ? "Aún no hay registros de riego." : "No watering logs yet." }
    static var noInsightsYet: String { es ? "Aún no hay análisis. Agrega registros de riego para ver recomendaciones." : "No insights yet. Add watering logs to see recommendations." }
    static var howToGetStarted: String { es ? "Cómo Empezar" : "How to Get Started" }
    static var tryExampleData: String { es ? "Probar Datos de Ejemplo" : "Try Example Data" }

    // MARK: - Footers / Descriptions

    static var displayUnitsFooter: String { es ? "Cambiar las unidades actualiza cómo se muestran los valores. Los datos almacenados no se modifican." : "Changing units updates how values are displayed. Stored data is never modified." }
    static var themeFooter: String { es ? "Cambiar entre modo Día y Oscuro." : "Switch between Day and Dark mode." }
    static var exportFooter: String { es ? "Exportar datos del cultivo como archivo de texto." : "Export grow data as a text file." }
    static var timestampFooter: String { es ? "Esta marca de tiempo se registra cuando guardas el cultivo." : "This timestamp is recorded when you save the grow." }
    static var maxRetentionDescription: String { es ? "El volumen máximo de agua que el medio puede retener antes de que comience el drenaje." : "The maximum volume of water the medium can hold before runoff begins." }
    static var calculatorFooter: String { es ? "¿No conoces tu capacidad? Usa la calculadora para derivarla de un riego de prueba." : "Don't know your capacity? Use the calculator to derive it from a test watering." }
    static var goalRunoffDescription: String { es ? "El porcentaje de drenaje que el algoritmo Siguiente intentará alcanzar. Por defecto 15% si se deja en blanco." : "The runoff percentage the Next algorithm will target. Defaults to 15% if left blank." }
    static var optional: String { es ? "Opcional" : "Optional" }

    // MARK: - Delete Confirmations

    static var deleteGrow: String { es ? "Eliminar Cultivo" : "Delete Grow" }
    static var deletePlant: String { es ? "Eliminar Planta" : "Delete Plant" }
    static var deleteLog: String { es ? "Eliminar Registro" : "Delete Log" }

    static func deleteGrowMessage(_ name: String) -> String {
        es
            ? "¿Estás seguro de que quieres eliminar \"\(name)\"? Todas las plantas y sus registros de riego en este cultivo serán eliminados permanentemente. Esta acción no se puede deshacer."
            : "Are you sure you want to delete \"\(name)\"? All plants and their watering logs in this grow will be permanently deleted. This action cannot be undone."
    }

    static func deletePlantMessage(_ name: String) -> String {
        es
            ? "¿Estás seguro de que quieres eliminar \"\(name)\"? Todos los registros de riego de esta planta serán eliminados permanentemente. Esta acción no se puede deshacer."
            : "Are you sure you want to delete \"\(name)\"? All watering logs for this plant will be permanently deleted. This action cannot be undone."
    }

    static func deleteLogMessage(_ dateFormatted: String) -> String {
        es
            ? "¿Eliminar el registro de \(dateFormatted)? Esta acción no se puede deshacer."
            : "Delete the log from \(dateFormatted)? This action cannot be undone."
    }

    // MARK: - Limit Exceeded

    static var growLimitReached: String { es ? "Límite de Cultivos Alcanzado" : "Grow Limit Reached" }
    static var plantLimitReached: String { es ? "Límite de Plantas Alcanzado" : "Plant Limit Reached" }

    static func growLimitMessage(_ max: Int) -> String {
        es
            ? "Has alcanzado el máximo de \(max) cultivos. Elimina un cultivo para crear uno nuevo."
            : "You've reached the maximum of \(max) grows. Delete a grow to create a new one."
    }

    static func perGrowPlantLimitMessage(_ max: Int) -> String {
        es
            ? "Has alcanzado el máximo de \(max) plantas por cultivo. Elimina una planta para crear una nueva."
            : "You've reached the maximum of \(max) plants per grow. Delete a plant to create a new one."
    }

    static func totalPlantLimitMessage(_ max: Int) -> String {
        es
            ? "Has alcanzado el máximo de \(max) plantas totales. Elimina una planta de cualquier cultivo para crear una nueva."
            : "You've reached the maximum of \(max) total plants. Delete a plant from any grow to create a new one."
    }

    // MARK: - Accessibility Labels

    static var settingsLabel: String { es ? "Configuración" : "Settings" }
    static var helpLabel: String { es ? "Ayuda" : "Help" }
    static var backLabel: String { es ? "Atrás" : "Back" }
    static var addGrowLabel: String { es ? "Agregar Cultivo" : "Add Grow" }
    static var addPlantLabel: String { es ? "Agregar Planta" : "Add Plant" }
    static var addWateringLabel: String { es ? "Agregar Riego" : "Add Watering" }
    static var deleteGrowLabel: String { es ? "Eliminar Cultivo" : "Delete Grow" }
    static var deletePlantLabel: String { es ? "Eliminar Planta" : "Delete Plant" }
    static var deleteLogLabel: String { es ? "Eliminar Registro" : "Delete Log" }
    static var chartLabel: String { es ? "Gráfico" : "Chart" }
    static var showLogs: String { es ? "Mostrar Registros" : "Show Logs" }
    static var showChart: String { es ? "Mostrar Gráfico" : "Show Chart" }
    static var dismissDialog: String { es ? "Cerrar diálogo" : "Dismiss dialog" }
    static var expandLogDetails: String { es ? "Expandir detalles del registro" : "Expand log details" }
    static var collapseLogDetails: String { es ? "Contraer detalles del registro" : "Collapse log details" }
    static var doubleTapExpandCollapse: String { es ? "Toca dos veces para expandir o contraer detalles" : "Double tap to expand or collapse details" }
    static var savedLabel: String { es ? "Guardado" : "Saved" }

    static func selectItem(_ name: String) -> String { es ? "Seleccionar \(name)" : "Select \(name)" }
    static func deselectItem(_ name: String) -> String { es ? "Deseleccionar \(name)" : "Deselect \(name)" }
    static var selectLog: String { es ? "Seleccionar registro" : "Select log" }
    static var deselectLog: String { es ? "Deseleccionar registro" : "Deselect log" }

    static func growsCount(_ count: Int, max: Int) -> String {
        es ? "Cultivos, \(count) de \(max)" : "Grows, \(count) of \(max)"
    }
    static func plantsCount(_ count: Int, max: Int) -> String {
        es ? "Plantas, \(count) de \(max)" : "Plants, \(count) of \(max)"
    }
    static func maxGrowsReached(_ max: Int) -> String {
        es ? "Máximo de \(max) cultivos alcanzado" : "Maximum of \(max) grows reached"
    }
    static func maxPlantsReached(_ max: Int) -> String {
        es ? "Máximo de \(max) plantas alcanzado" : "Maximum of \(max) plants reached"
    }
    static var tapPlusCreateGrow: String { es ? "Toca más para crear tu primer cultivo" : "Tap plus to create your first grow" }
    static var tapPlusAddPlant: String { es ? "Toca más para agregar tu primera planta" : "Tap plus to add your first plant" }
    static var loadExampleData: String { es ? "Cargar cultivo de ejemplo con datos de riego" : "Load example grow with sample watering data" }
    static func exportGrowData(_ name: String) -> String {
        es ? "Exportar datos de \(name)" : "Export \(name) data"
    }
    static func viewAllLogsCount(_ count: Int) -> String {
        es ? "Ver Todos los Registros, \(count) total" : "View All Logs, \(count) total"
    }
    static func waterAddedAccessibility(_ unit: String) -> String {
        es ? "Agua Agregada en \(unit)" : "Water Added in \(unit)"
    }
    static func runoffCollectedAccessibility(_ unit: String) -> String {
        es ? "Drenaje Recolectado en \(unit)" : "Runoff Collected in \(unit)"
    }
    static func maxRetentionAccessibility(_ unit: String) -> String {
        es ? "Capacidad Máx. de Retención en \(unit)" : "Max Retention Capacity in \(unit)"
    }
    static func temperatureAccessibility(_ unit: String) -> String {
        es ? "Temperatura en \(unit)" : "Temperature in \(unit)"
    }
    static var humidityPercent: String { es ? "Porcentaje de humedad" : "Humidity percent" }
    static var potSize: String { es ? "Tamaño de Maceta" : "Pot Size" }
    static var mediumType: String { es ? "Tipo de Medio" : "Medium Type" }
    static var goalRunoffPercent: String { es ? "Porcentaje de Drenaje Objetivo" : "Goal Runoff Percent" }
    static var calculateHint: String {
        es ? "Calcular retención máx. con agua agregada y drenaje" : "Calculate max retention from water added and runoff"
    }
    static func calcWaterAddedAccessibility(_ unit: String) -> String {
        es ? "Calculadora Agua Agregada en \(unit)" : "Calculator Water Added in \(unit)"
    }
    static func calcRunoffAccessibility(_ unit: String) -> String {
        es ? "Calculadora Drenaje Recolectado en \(unit)" : "Calculator Runoff Collected in \(unit)"
    }

    // MARK: - Chart

    static var temp: String { es ? "Temp" : "Temp" }
    static var overTime: String { es ? " en el Tiempo" : " Over Time" }
    static func chartLineName(_ label: String) -> String {
        es ? "Línea de gráfico de \(label)" : "\(label) chart line"
    }
    static func chartLineActive() -> String {
        es ? "Activo. Toca dos veces para ocultar." : "Active. Double tap to hide."
    }
    static func chartLineInactive() -> String {
        es ? "Inactivo. Toca dos veces para mostrar." : "Inactive. Double tap to show."
    }
    static func chartLineNoData(_ label: String) -> String {
        es ? "No hay datos de \(label) disponibles." : "No \(label) data available."
    }
    static var retainedWater: String { es ? "Agua retenida" : "Retained water" }
    static var temperatureLower: String { es ? "temperatura" : "temperature" }
    static var humidityLower: String { es ? "humedad" : "humidity" }
    static func chartAccessibility(_ lines: [String], dataCount: Int) -> String {
        let joined = lines.joined(separator: ", ")
        return es
            ? "Gráfico de \(joined) en el tiempo con \(dataCount) puntos de datos"
            : "\(joined) over time chart with \(dataCount) data points"
    }
    static func capacityAccessibility(_ percent: String) -> String {
        es ? "Capacidad \(percent)" : "Capacity \(percent)"
    }

    // MARK: - Pluralization

    static func plantCount(_ count: Int) -> String {
        if es { return "\(count) planta\(count == 1 ? "" : "s")" }
        return "\(count) plant\(count == 1 ? "" : "s")"
    }

    // MARK: - Launch Screen

    static var evapotrack: String { "EVAPOTRACK" }
    static var launchSlogan: String { es ? "Optimiza el riego de plantas" : "Optimize plant watering" }
    static var launchAccessibility: String { es ? "Evapotrack. Optimiza el riego de plantas." : "Evapotrack. Optimize plant watering." }

    // MARK: - Content Unavailable

    static var growNotFound: String { es ? "Cultivo No Encontrado" : "Grow Not Found" }
    static var plantNotFound: String { es ? "Planta No Encontrada" : "Plant Not Found" }

    // MARK: - Alert Titles

    static var error: String { es ? "Error" : "Error" }

    // MARK: - Plant Info Labels

    static var pot: String { es ? "Maceta" : "Pot" }
    static var medium: String { es ? "Medio" : "Medium" }
    static var maxCapacity: String { es ? "Cap. Máx." : "Max Capacity" }
    static var goalRunoff: String { es ? "Obj. Drenaje" : "Goal Runoff" }

    // MARK: - Example Data

    static var exampleGrow: String { es ? "Cultivo de Ejemplo" : "Example Grow" }
    static var examplePlant: String { es ? "Planta de Ejemplo" : "Example Plant" }

    // MARK: - Error Messages

    static var failedDeleteGrow: String { es ? "No se pudo eliminar el cultivo. Inténtalo de nuevo." : "Failed to delete grow. Please try again." }
    static var failedDeletePlant: String { es ? "No se pudo eliminar la planta. Inténtalo de nuevo." : "Failed to delete plant. Please try again." }
    static var failedDeleteLog: String { es ? "No se pudo eliminar el registro. Inténtalo de nuevo." : "Failed to delete log. Please try again." }
    static var unableToSave: String { es ? "No se pudo guardar. Inténtalo de nuevo." : "Unable to save. Please try again." }
    static var failedToSave: String { es ? "Error al guardar. Inténtalo de nuevo." : "Failed to save. Please try again." }

    // MARK: - Validation Errors

    static func growNameInvalid(_ max: Int) -> String {
        es ? "El nombre del cultivo debe tener entre 1 y \(max) caracteres y no estar en blanco." : "Grow name must be 1–\(max) characters and not blank."
    }
    static var growNameDuplicate: String { es ? "Ya existe un cultivo con este nombre." : "A grow with this name already exists." }
    static func plantNameInvalid(_ max: Int) -> String {
        es ? "El nombre de la planta debe tener entre 1 y \(max) caracteres y no estar en blanco." : "Plant name must be 1–\(max) characters and not blank."
    }
    static var plantNameDuplicate: String { es ? "Ya existe una planta con este nombre en este cultivo." : "A plant with this name already exists in this grow." }
    static var potSizeBlank: String { es ? "El tamaño de la maceta no debe estar en blanco." : "Pot size must not be blank." }
    static var mediumTypeBlank: String { es ? "El tipo de medio no debe estar en blanco." : "Medium type must not be blank." }
    static var maxRetentionRange: String { es ? "La capacidad máx. de retención debe estar entre 0.001 y 100 litros." : "Max retention capacity must be between 0.001 and 100 liters." }
    static var waterAddedRange: String { es ? "El agua agregada debe estar entre 0.001 y 100 litros." : "Water added must be between 0.001 and 100 liters." }
    static var runoffRange: String { es ? "El drenaje debe ser ≥ 0 y menor que el agua agregada." : "Runoff must be ≥ 0 and less than water added." }
    static var temperatureRange: String { es ? "La temperatura debe estar entre -50 y 60 °C." : "Temperature must be between -50 and 60 °C." }
    static var humidityRange: String { es ? "La humedad debe estar entre 0 y 100%." : "Humidity must be between 0 and 100%." }
    static var dateInFuture: String { es ? "La fecha no puede ser en el futuro." : "Date cannot be in the future." }
    static var maxRetentionMustBeNumber: String { es ? "La capacidad máx. de retención debe ser un número." : "Max retention capacity must be a number." }
    static var goalRunoffMustBeNumber: String { es ? "El % de drenaje objetivo debe ser un número." : "Goal Runoff % must be a number." }
    static var goalRunoffRange: String { es ? "El % de drenaje objetivo debe estar entre 0.1 y 99.9." : "Goal Runoff % must be between 0.1 and 99.9." }
    static var waterAddedMustBeNumber: String { es ? "El agua agregada debe ser un número." : "Water added must be a number." }
    static var runoffMustBeNumber: String { es ? "El drenaje debe ser un número." : "Runoff must be a number." }
    static var runoffMustBePositive: String { es ? "El drenaje recolectado debe ser mayor que 0." : "Runoff collected must be greater than 0." }
    static var retainedExceedsCapacity: String { es ? "El volumen retenido excede el 105% de la Capacidad Máx. de Retención. Verifica tus valores de Agua Agregada y Drenaje." : "Retained volume exceeds 105% of Max Retention Capacity. Check your Water Added and Runoff values." }
    static var duplicateLogTimestamp: String { es ? "Ya existe un registro de riego en esta fecha y hora." : "A watering log already exists at this date and time." }
    static var temperatureMustBeNumber: String { es ? "La temperatura debe ser un número." : "Temperature must be a number." }
    static var humidityMustBeNumber: String { es ? "La humedad debe ser un número." : "Humidity must be a number." }

    // MARK: - Goal with dynamic percent

    static func goalLabel(_ percent: String) -> String {
        es ? "Objetivo (\(percent))" : "Goal (\(percent))"
    }

    // MARK: - How To Content

    // General context
    static var whatIsEvapotrack: String { es ? "¿Qué es Evapotrack?" : "What Is Evapotrack?" }
    static var whatIsEvapotrackHighlight: String { "Evapotrack" }
    static var whatIsEvapotrackBullets: [String] {
        es ? [
            "Evapotrack te ayuda a rastrear y optimizar el riego de tus plantas registrando cuánta agua agregas y cuánta drena.",
            "La app calcula métricas clave como el volumen Retenido, % de Capacidad, y una cantidad de riego recomendada basada en tu historial.",
            "Todos los datos se almacenan localmente en tu dispositivo. Puedes descargar tus datos directamente desde Configuración."
        ] : [
            "Evapotrack helps you track and optimize watering for your plants by recording how much water you add and how much runs off.",
            "The app calculates key metrics like Retained volume, Capacity %, and a recommended Next watering amount based on your history.",
            "All data is stored locally on your device. You can download your data directly from Settings."
        ]
    }

    static var growsAndPlants: String { es ? "Cultivos y Plantas" : "Grows and Plants" }
    static var growsAndPlantsHighlight: String { es ? "Cultivos" : "Grows" }
    static var growsAndPlantsBullets: [String] {
        es ? [
            "Un Cultivo es un grupo que contiene una o más plantas. Usa cultivos para organizar plantas por ubicación, ciclo, o cualquier agrupación que tenga sentido para ti.",
            "Toca + en la pantalla Mis Cultivos para crear un nuevo cultivo. Cada cultivo registra su nombre y la fecha de creación.",
            "Toca un cultivo para abrir su lista de plantas. Desde ahí, toca + para agregar plantas a ese cultivo.",
            "Eliminar un cultivo eliminará permanentemente todas las plantas dentro de él y todos sus registros de riego."
        ] : [
            "A Grow is a group that contains one or more plants. Use grows to organize plants by location, cycle, or any grouping that makes sense for you.",
            "Tap + on the My Grows screen to create a new grow. Each grow records its name and the date it was created.",
            "Tap a grow to open its plant list. From there, tap + to add plants to that grow.",
            "Deleting a grow will permanently delete all plants inside it and all of their watering logs."
        ]
    }

    static var howToCreatePlant: String { es ? "Cómo Crear una Planta" : "How to Create a Plant" }
    static var howToCreatePlantHighlight: String { es ? "Planta" : "Plant" }
    static var howToCreatePlantBullets: [String] {
        es ? [
            "Abre un cultivo, luego toca + para comenzar a crear una nueva planta.",
            "Ingresa los campos requeridos: Nombre de la Planta, Tamaño de Maceta, Tipo de Medio, y Capacidad Máx. de Retención.",
            "Si ya conoces tu Capacidad Máx. de Retención, ingrésala directamente. Si no, usa la calculadora incorporada para derivarla de un riego de prueba.",
            "Las plantas no pueden editarse después de su creación. Asegúrate de que todos los campos sean correctos antes de guardar.",
            "Eliminar una planta eliminará permanentemente todos sus registros de riego."
        ] : [
            "Open a grow, then tap + to start creating a new plant.",
            "Enter the required fields: Plant Name, Pot Size, Medium Type, and Max Retention Capacity.",
            "If you already know your Max Retention Capacity, enter it directly. Otherwise, use the built-in calculator to derive it from a test watering.",
            "Plants cannot be edited after creation. Make sure all fields are correct before saving.",
            "Deleting a plant will permanently delete all of its watering logs."
        ]
    }

    static var whatIsMaxRetention: String { es ? "¿Qué es la Capacidad Máx. de Retención?" : "What Is Max Retention Capacity?" }
    static var whatIsMaxRetentionHighlight: String { es ? "Capacidad Máx. de Retención" : "Max Retention Capacity" }
    static var whatIsMaxRetentionBullets: [String] {
        es ? [
            "La Capacidad Máx. de Retención es el volumen máximo de agua que tu medio de cultivo puede absorber y retener antes de que comience el drenaje.",
            "Este valor es fundamental para cómo Evapotrack calcula el % de Capacidad, el Promedio Retenido, y la Cantidad de Riego Siguiente.",
            "Para determinarla: riega tu medio lentamente hasta que comience el drenaje, luego resta el drenaje del agua que agregaste. El resultado es tu Capacidad Máx. de Retención.",
            "Un medio más saturado producirá más drenaje. Una Capacidad Máx. de Retención precisa lleva a mejores recomendaciones."
        ] : [
            "Max Retention Capacity is the maximum volume of water your growing medium can absorb and hold before runoff begins.",
            "This value is central to how Evapotrack calculates Capacity %, Average Retained, and the Next Watering Amount.",
            "To determine it: water your medium slowly until runoff starts, then subtract the runoff from the water you added. The result is your Max Retention Capacity.",
            "A more saturated medium will produce more runoff. An accurate Max Retention Capacity leads to better recommendations."
        ]
    }

    static var howToDownloadData: String { es ? "Cómo Descargar los Datos de tu Cultivo" : "How to Download Your Grow Data" }
    static var howToDownloadDataHighlight: String { es ? "Descargar" : "Download" }
    static var howToDownloadDataBullets: [String] {
        es ? [
            "Abre la lista de plantas de un cultivo, luego toca el ícono de engranaje para abrir Configuración.",
            "Desplázate hasta la sección Exportar Datos. Esta sección solo aparece cuando Configuración se abre desde dentro de un cultivo.",
            "Toca Exportar para generar un archivo de texto formateado con todas las plantas del cultivo, sus detalles, y cada registro de riego.",
            "Los valores se exportan en tus unidades de visualización elegidas (unidad de agua y unidad de temperatura).",
            "Elige dónde guardar o compartir el archivo usando el menú de compartir del sistema."
        ] : [
            "Open a grow's plant list, then tap the gear icon to open Settings.",
            "Scroll to the Export Data section. This section only appears when Settings is opened from within a grow.",
            "Tap Export to generate a formatted text file containing all plants in the grow, their details, and every watering log.",
            "Values are exported in your chosen display units (water unit and temperature unit).",
            "Choose where to save or share the file using the system share sheet."
        ]
    }

    // Add Watering context
    static var howToLogWatering: String { es ? "Cómo Registrar un Evento de Riego" : "How to Log a Watering Event" }
    static var howToLogWateringHighlight: String { es ? "Registrar" : "Log" }
    static var howToLogWateringBullets: [String] {
        es ? [
            "Desde el panel de una planta, toca + para agregar un nuevo evento de riego.",
            "Ingresa Agua Agregada y Drenaje Recolectado. Ambos son requeridos.",
            "Establece la Fecha y Hora correctas. No se permiten fechas futuras.",
            "Temperatura y Humedad son opcionales. Se registran para tu referencia pero no se usan en los cálculos.",
            "Los registros no pueden editarse después de su creación. Si un registro es incorrecto, elimínalo y crea uno nuevo."
        ] : [
            "From a plant's dashboard, tap + to add a new watering event.",
            "Enter Water Added and Runoff Collected. Both are required.",
            "Set the correct Date and Time. Future dates are not allowed.",
            "Temperature and Humidity are optional. They are recorded for your reference but are not used in any calculations.",
            "Logs cannot be edited after creation. If a log is incorrect, delete it and create a new one."
        ]
    }

    static var whatIsNext: String { es ? "¿Qué es Siguiente?" : "What Is Next?" }
    static var whatIsNextHighlight: String { es ? "Siguiente" : "Next" }
    static var whatIsNextBullets: [String] {
        es ? [
            "Siguiente es la cantidad de agua recomendada que se muestra en el panel de Análisis. Te indica cuánto regar la próxima vez para alcanzar tu % de Drenaje Objetivo.",
            "Puede aumentar o disminuir según tu historial para mantener tu drenaje lo más cerca posible de tu % de Drenaje Objetivo.",
            "La estimación se basa en tu historial reciente de riego — promedia tu último Retenido con tu promedio general para predecir la absorción.",
            "Cuantos más registros guardes, más precisa será la recomendación."
        ] : [
            "Next is the recommended water amount shown in the Insights panel. It tells you how much to water next time to hit your Goal Runoff %.",
            "It may increase or decrease based on your history to keep your runoff as close to your Goal Runoff % as possible.",
            "The estimate is based on your recent watering history — it averages your last Retained amount with your overall average to predict absorption.",
            "The more logs you record, the more accurate the recommendation becomes."
        ]
    }

    // Chart context
    static var readingTheChart: String { es ? "Lectura del Gráfico" : "Reading the Chart" }
    static var readingTheChartHighlight: String { es ? "Gráfico" : "Chart" }
    static var readingTheChartBullets: [String] {
        es ? [
            "El gráfico muestra tu volumen de agua Retenida a través de todos los registros almacenados para la planta, desde la fecha más antigua hasta la más reciente.",
            "Una tendencia ascendente en Retenido significa que tu medio está absorbiendo más agua con el tiempo, lo que puede indicar secado entre riegos o mayor absorción de la planta.",
            "Una tendencia descendente puede indicar que el medio se mantiene saturado o que tu volumen de riego está disminuyendo.",
            "Una línea plana y consistente significa que tu rutina de riego es estable y tu medio absorbe una cantidad predecible cada vez."
        ] : [
            "The chart plots your Retained water volume across all stored logs for the plant, from the earliest log date to the most recent.",
            "An upward trend in Retained means your medium is absorbing more water over time, which may indicate drying out between waterings or increased plant uptake.",
            "A downward trend may indicate the medium is staying saturated or that your watering volume is decreasing.",
            "A flat, consistent line means your watering routine is stable and your medium is absorbing a predictable amount each time."
        ]
    }

    static var tempHumidityOverlays: String { es ? "Superposiciones de Temperatura y Humedad" : "Temperature and Humidity Overlays" }
    static var tempHumidityOverlaysHighlight: String { es ? "Superposiciones" : "Overlays" }
    static var tempHumidityOverlaysBullets: [String] {
        es ? [
            "Activa las píldoras de Temp y Humedad para superponer datos ambientales en el gráfico.",
            "Cada superposición se renderiza en su propia escala para que la forma de la línea refleje los datos con precisión.",
            "Busca correlaciones: una temperatura ascendente a menudo aumenta la absorción de agua, mientras que una mayor humedad puede reducirla.",
            "Estos campos son opcionales. Si ningún registro incluye datos de temperatura o humedad, el botón estará deshabilitado."
        ] : [
            "Toggle the Temp and Humidity pills to overlay environmental data on the chart.",
            "Each overlay renders on its own scale so the line shape accurately reflects the data.",
            "Look for correlations: rising temperature often increases water uptake, while higher humidity may reduce it.",
            "These fields are optional. If no logs include temperature or humidity data, the toggle will be disabled."
        ]
    }

    static var wateringProtocol: String { es ? "Protocolo de Riego" : "Watering Protocol" }
    static var wateringProtocolHighlight: String { es ? "Protocolo" : "Protocol" }
    static var wateringProtocolBullets: [String] {
        es ? [
            "Riega tu medio lenta y uniformemente, siempre apuntando al drenaje.",
            "Siempre debes tener drenaje. El drenaje siempre debe ser menor que el Agua Agregada.",
            "Tu meta de drenaje se basa en el % de Drenaje Objetivo establecido para cada planta (por defecto 15%).",
            "Recolecta todo el drenaje en una bandeja y mídelo después de que la maceta termine de drenar.",
            "Resta el Drenaje Recolectado del Agua Agregada. Este es tu volumen Retenido — la cantidad de agua que el medio realmente absorbió."
        ] : [
            "Water your medium slowly and evenly, always aiming for runoff.",
            "You must always have runoff. Runoff must always be less than Water Added.",
            "Your runoff goal is based on the Goal Runoff % set for each plant (default 15%).",
            "Collect all runoff in a tray and measure it after the pot finishes draining.",
            "Subtract Runoff Collected from Water Added. This is your Retained volume — the amount of water the medium actually absorbed."
        ]
    }
}
