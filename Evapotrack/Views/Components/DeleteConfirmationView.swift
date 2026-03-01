// DeleteConfirmationView.swift
// Evapotrack
//
// Reusable custom delete confirmation modal.
// Replaces system .alert() for larger, styled text
// with centered bold title and readable body text.
// Presented as a full-screen overlay with dimmed background.

import SwiftUI

struct DeleteConfirmationView: View {
    let title: String
    let message: String
    let onDelete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            // Dimmed background
            Color.evInkBlack.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }
                .accessibilityLabel("Dismiss dialog")
                .accessibilityAddTraits(.isButton)

            // Modal card
            VStack(spacing: 20) {
                // Centered bold title
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.evPrimaryText)
                    .multilineTextAlignment(.center)

                // Body message
                Text(message)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.evSecondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                // Action buttons
                HStack(spacing: 16) {
                    // Cancel button
                    Button {
                        onCancel()
                    } label: {
                        Text("Cancel")
                            .font(.body.weight(.bold))
                            .foregroundStyle(Color.evSlateGray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.evSlateGray, lineWidth: 1.5)
                            )
                    }

                    // Delete button
                    Button {
                        onDelete()
                    } label: {
                        Text("Delete")
                            .font(.body.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red)
                            )
                    }
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
    }
}
