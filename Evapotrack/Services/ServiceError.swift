// © 2026 Evapotrack. All rights reserved.
// ServiceError.swift
// Evapotrack
//
// Shared error type and save helper for service-layer operations.

import Foundation
import OSLog
import SwiftData

enum ServiceError: LocalizedError {
    case limitExceeded

    var errorDescription: String? {
        switch self {
        case .limitExceeded:
            return "Entity limit reached."
        }
    }
}

/// How a service writes its changes. Production uses `ModelContext.save()`;
/// tests substitute a failing save to exercise the rollback path.
typealias SaveHandler = (ModelContext) throws -> Void

extension ModelContext {

    /// Saves, or on failure discards every pending change so the objects in
    /// memory match what is on disk, logs the reason, and rethrows. Without the
    /// rollback, a failed insert or delete stays pending and autosave could
    /// commit it later, after the user was told it failed.
    func saveOrRollback(using save: SaveHandler, action: String) throws {
        do {
            try save(self)
        } catch {
            rollback()
            Logger.services.error("\(action, privacy: .public) failed and was rolled back: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}
