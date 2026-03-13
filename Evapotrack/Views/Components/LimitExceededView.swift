// LimitExceededView.swift
// Evapotrack
//
// Reusable modal shown when a creation limit is exceeded.
// Styled consistently with DeleteConfirmationView.
// Presented as a full-screen overlay with dimmed background.

import SwiftUI

struct LimitExceededView: View {
    let title: String
    let message: String
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.evInkBlack.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onClose() }
                .accessibilityLabel("Dismiss dialog")
                .accessibilityAddTraits(.isButton)

            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(red: 0.85, green: 0.55, blue: 0.1))
                    .accessibilityHidden(true)

                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.evPrimaryText)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.evSecondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    onClose()
                } label: {
                    Text("Close")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.evPrimaryBlue)
                        )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.evBackground)
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            )
            .padding(.horizontal, 32)
        }
        .transition(.opacity)
        .accessibilityAddTraits(.isModal)
    }
}
