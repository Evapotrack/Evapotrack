// © 2026 Evapotrack. All rights reserved.
// ServiceError.swift
// Evapotrack
//
// Shared error type for service-layer operations.

import Foundation

enum ServiceError: LocalizedError {
    case limitExceeded

    var errorDescription: String? {
        switch self {
        case .limitExceeded:
            return "Entity limit reached."
        }
    }
}
