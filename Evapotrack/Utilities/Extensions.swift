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

    /// Adds extra top padding on iPad for visual breathing room.
    func iPadTopPadding(_ amount: CGFloat = 20) -> some View {
        modifier(IPadTopPaddingModifier(amount: amount))
    }

    /// Presents a sheet on iPhone and a fullScreenCover on iPad so form content fits without scrolling.
    func adaptiveSheet<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(AdaptiveSheetModifier(isPresented: isPresented, onDismiss: onDismiss, sheetContent: content))
    }
}

// MARK: - IPadTopPaddingModifier

private struct IPadTopPaddingModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    let amount: CGFloat

    func body(content: Content) -> some View {
        if sizeClass == .regular {
            content.safeAreaInset(edge: .top, spacing: 0) {
                Spacer().frame(height: amount)
            }
        } else {
            content
        }
    }
}

// MARK: - AdaptiveSheetModifier

private struct AdaptiveSheetModifier<SheetContent: View>: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    @ViewBuilder let sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        if sizeClass == .regular {
            content.fullScreenCover(isPresented: $isPresented, onDismiss: onDismiss, content: sheetContent)
        } else {
            content.sheet(isPresented: $isPresented, onDismiss: onDismiss, content: sheetContent)
        }
    }
}