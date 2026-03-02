// EvapotrackApp.swift
// Evapotrack
//
// App entry point. Configures SwiftData model container,
// injects shared SettingsViewModel, and sets GrowListView as root.
// Shows an animated launch screen before revealing the main content.

import SwiftUI
import SwiftData

@main
struct EvapotrackApp: App {

    @State private var settingsVM = SettingsViewModel()
    @State private var showLaunch = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                GrowListView()
                    .environment(settingsVM)
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
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showLaunch = false
                                }
                            }
                        }
                }
            }
            .preferredColorScheme(settingsVM.colorScheme)
        }
        .modelContainer(for: [Grow.self, Plant.self, WateringLog.self])
    }
}
