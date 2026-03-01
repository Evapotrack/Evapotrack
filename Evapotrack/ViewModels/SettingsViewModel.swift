// SettingsViewModel.swift
// Evapotrack
//
// Reads and writes UserSettings to UserDefaults via JSON.
// Changing units instantly updates all displayed values across
// the app but never modifies any stored internal values.

import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {

    var settings: UserSettings = .default

    init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: AppConstants.userSettingsKey),
              let decoded = try? JSONDecoder().decode(UserSettings.self, from: data)
        else { return }
        settings = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: AppConstants.userSettingsKey)
    }

    func reset() {
        settings = .default
        save()
    }
}
