// © 2026 Evapotrack. All rights reserved.
// Extensions.swift
// Evapotrack
//
// Convenience extensions on Foundation types used throughout the app.

import Foundation

// MARK: - Date

extension Date {
    /// Formats the date for display in lists (e.g. "Mar 1, 2026").
    var shortFormatted: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    /// Formats the date with time for detail views.
    var longFormatted: String {
        formatted(date: .abbreviated, time: .shortened)
    }

    /// Formats only the time for display (e.g. "2:30 PM").
    var timeFormatted: String {
        formatted(date: .omitted, time: .shortened)
    }

    /// Start of day for the receiver.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Integer number of whole days between two dates.
    static func daysBetween(start: Date, end: Date) -> Int {
        let components = Calendar.current.dateComponents([.day], from: start.startOfDay, to: end.startOfDay)
        return components.day ?? 0
    }

    /// Hours between two dates as a Double.
    static func hoursBetween(start: Date, end: Date) -> Double {
        end.timeIntervalSince(start) / 3600.0
    }
}

// MARK: - View

import SwiftUI

extension View {
    /// Limits a bound text field string to maxLength characters during typing.
    func textLimit(_ text: Binding<String>, maxLength: Int) -> some View {
        self.onChange(of: text.wrappedValue) { oldValue, newValue in
            if newValue.count > maxLength {
                text.wrappedValue = String(newValue.prefix(maxLength))
            }
        }
    }
}