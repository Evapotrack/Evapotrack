// Logger.swift
// Evapotrack
//
// Thin wrapper around os.Logger providing subsystem-scoped
// logging categories for Console.app filtering.

import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.evapotrack"

    /// Service-layer operations.
    static let services  = Logger(subsystem: subsystem, category: "services")
    /// ViewModel actions.
    static let viewModel = Logger(subsystem: subsystem, category: "viewModel")
}
