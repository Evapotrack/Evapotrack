// © 2026 Evapotrack. All rights reserved.
// EvapotrackApp.swift
// Evapotrack
//
// App entry point. Opens the SwiftData store (versioned schema with a
// migration plan), injects the shared SettingsViewModel, and sets
// GrowListView as root. Shows an animated launch screen before revealing
// the main content. If the store cannot be opened, shows an explanation
// instead of crashing or starting with an empty store.
// At launch, removes watering-photo files that no log refers to (see
// PhotoMaintenance); it runs on the main actor, so it can never interleave
// with adding or deleting a log.

import SwiftUI
import SwiftData
import OSLog

@main
struct EvapotrackApp: App {

    @State private var settingsVM = SettingsViewModel()
    @State private var showLaunch = true
    private let store: Result<ModelContainer, Error>

    init() {
        do {
            store = .success(try PersistenceController.makeContainer())
        } catch {
            Logger.services.fault("Could not open the data store: \(error.localizedDescription, privacy: .public)")
            store = .failure(error)
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch store {
                case .success(let container):
                    mainContent
                        .modelContainer(container)
                        .task {
                            PhotoMaintenance.removeOrphanedFiles(context: container.mainContext)
                        }
                case .failure:
                    DataStoreErrorView()
                        .environment(settingsVM)
                }
            }
            .preferredColorScheme(settingsVM.colorScheme)
        }
    }

    private var mainContent: some View {
        ZStack {
            GrowListView()
                .environment(settingsVM)
                // Date pickers and formatted Text follow the app's language.
                .environment(\.locale, settingsVM.settings.language.locale)
                .tint(.evPrimaryBlue)
                .fontDesign(.rounded)
                .overlay {
                    // Subtle 3% dimming in Day mode for a softer appearance
                    if settingsVM.settings.appearanceMode == .light {
                        Color.black.opacity(0.025)
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    }
                }
                .opacity(showLaunch ? 0 : 1)

            if showLaunch {
                LaunchView()
                    .task {
                        try? await Task.sleep(for: .seconds(3))
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showLaunch = false
                        }
                    }
            }
        }
    }
}
