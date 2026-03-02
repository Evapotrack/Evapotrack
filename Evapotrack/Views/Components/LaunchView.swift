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

            VStack(spacing: 24) {
                Image("LaunchIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                Text("EVAPOTRACK")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.evPrimaryText)
                    .kerning(2)
            }
            .opacity(iconOpacity)
        }
        .onAppear {
            // Fade in
            withAnimation(.easeIn(duration: 0.8)) {
                iconOpacity = 1.0
            }
            // Hold longer, then fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeOut(duration: 0.5)) {
                    iconOpacity = 0
                }
            }
        }
    }
}
