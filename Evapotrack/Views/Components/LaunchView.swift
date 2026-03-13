// LaunchView.swift
// Evapotrack
//
// Animated launch screen that shows the app icon fading in and out
// before transitioning to the main content.
// Parent (EvapotrackApp) controls when this view is removed.

import SwiftUI

struct LaunchView: View {
    @State private var iconOpacity: Double = 0
    @State private var sloganOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.evBackground
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image("LaunchIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(color: .evPrimaryBlue.opacity(0.2), radius: 16, y: 6)
                    .accessibilityHidden(true)

                Text("EVAPOTRACK")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.evPrimaryText)
                    .kerning(2)

                Text("Optimize plant watering")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.evSecondaryText)
                    .opacity(sloganOpacity)
            }
            .opacity(iconOpacity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Evapotrack. Optimize plant watering.")
        }
        .task {
            // Fade in icon and title
            withAnimation(.easeIn(duration: 0.8)) {
                iconOpacity = 1.0
            }
            // Slogan fades in slightly after
            try? await Task.sleep(for: .seconds(0.6))
            withAnimation(.easeIn(duration: 0.6)) {
                sloganOpacity = 1.0
            }
            // Hold, then fade out
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.easeOut(duration: 0.5)) {
                iconOpacity = 0
            }
        }
    }
}
