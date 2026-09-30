// © 2026 Evapotrack. All rights reserved.
// SettingsViewModel.swift
// Evapotrack
//
// Reads and writes UserSettings to UserDefaults via JSON.
// The store is injectable so tests use their own suite instead of the
// app's real settings.
// Changing units instantly updates all displayed values across
// the app but never modifies any stored internal values.

import Foundation
import SwiftUI
import Observation
import OSLog

@Observable
@MainActor
final class SettingsViewModel {

    var settings: UserSettings = .default {
        didSet { Strings.current = settings.language }
    }

    /// Single source of truth for the app's color scheme.
    var colorScheme: ColorScheme {
        settings.appearanceMode == .dark ? .dark : .light
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
        Strings.current = settings.language
    }

    func load() {
        guard let data = defaults.data(forKey: AppConstants.userSettingsKey) else { return }
        do {
            settings = try JSONDecoder().decode(UserSettings.self, from: data)
            Strings.current = settings.language
        } catch {
            Logger.viewModel.error("Failed to decode UserSettings: \(error.localizedDescription)")
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(settings)
            defaults.set(data, forKey: AppConstants.userSettingsKey)
            Strings.current = settings.language
        } catch {
            Logger.viewModel.error("Failed to encode UserSettings: \(error.localizedDescription)")
        }
    }

    func reset() {
        settings = .default
        Strings.current = settings.language
        save()
    }
}
