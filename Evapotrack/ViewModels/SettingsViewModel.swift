// SettingsViewModel.swift
// Evapotrack
//
// Reads and writes UserSettings to UserDefaults via JSON.
// Changing units instantly updates all displayed values across
// the app but never modifies any stored internal values.

import Foundation
import SwiftUI
import Observation
import OSLog

@Observable
@MainActor
final class SettingsViewModel {

    var settings: UserSettings = .default

    /// Single source of truth for the app's color scheme.
    var colorScheme: ColorScheme {
        settings.appearanceMode == .dark ? .dark : .light
    }

    init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.userSettingsKey) else { return }
        do {
            settings = try JSONDecoder().decode(UserSettings.self, from: data)
        } catch {
            Logger.viewModel.error("Failed to decode UserSettings: \(error.localizedDescription)")
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: AppConstants.userSettingsKey)
        } catch {
            Logger.viewModel.error("Failed to encode UserSettings: \(error.localizedDescription)")
        }
    }

    func reset() {
        settings = .default
        save()
    }
}
