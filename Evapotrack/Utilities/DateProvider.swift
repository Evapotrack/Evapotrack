// DateProvider.swift
// Evapotrack
//
// Abstraction over the current date for testability.

import Foundation

nonisolated protocol DateProviding: Sendable {
    var now: Date { get }
}

struct SystemDateProvider: DateProviding {
    nonisolated var now: Date { .now }
}

struct MockDateProvider: DateProviding {
    let fixedDate: Date
    nonisolated var now: Date { fixedDate }
}
