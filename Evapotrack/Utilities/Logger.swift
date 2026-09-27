// © 2026 Evapotrack. All rights reserved.
// Logger.swift
// Evapotrack
//
// Thin wrapper around os.Logger providing subsystem-scoped
// logging categories for Console.app filtering. The loggers are
// nonisolated so background work (photo processing) can log too.

import OSLog

extension Logger {
    nonisolated private static let subsystem = Bundle.main.bundleIdentifier ?? "com.evapotrack"

    /// Service-layer operations.
    nonisolated static let services  = Logger(subsystem: subsystem, category: "services")
    /// ViewModel actions.
    nonisolated static let viewModel = Logger(subsystem: subsystem, category: "viewModel")
    /// Photo import, storage and cleanup (runs off the main actor).
    nonisolated static let photos    = Logger(subsystem: subsystem, category: "photos")
}
