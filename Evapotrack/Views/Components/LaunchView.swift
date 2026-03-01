// LaunchView.swift
// Evapotrack
//
// Animated launch screen that shows the app icon fading in and out
// before transitioning to the main content.
// Parent (EvapotrackApp) controls when this view is removed.

import SwiftUI

struct LaunchView: View {
    @State private var iconOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.evBackground
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.evPrimaryBlue)

                Text("Evapotrack")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.evPrimaryText)
            }
            .opacity(iconOpacity)
        }
        .onAppear {
            // Fade in
            withAnimation(.easeIn(duration: 0.6)) {
                iconOpacity = 1.0
            }
            // Hold briefly, then fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    iconOpacity = 0
                }
            }
        }
    }
}
