// DateProvider.swift
// Evapotrack
//
// Abstraction over the current date for testability.

import Foundation

protocol DateProviding {
    var now: Date { get }
}

struct SystemDateProvider: DateProviding {
    var now: Date { .now }
}

struct MockDateProvider: DateProviding {
    let fixedDate: Date
    var now: Date { fixedDate }
}
