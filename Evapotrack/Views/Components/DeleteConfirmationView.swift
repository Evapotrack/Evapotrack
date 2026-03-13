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

    private var styledMessage: Text {
        let keyword = "permanently"
        guard let range = message.range(of: keyword) else {
            return Text(message)
        }
        let before = String(message[message.startIndex..<range.lowerBound])
        let after = String(message[range.upperBound..<message.endIndex])
        return Text(before) + Text(keyword).bold() + Text(after)
    }

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
                styledMessage
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
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.evSlateGray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.evSlateGray, lineWidth: 1.5)
                            )
                    }

                    // Delete button
                    Button {
                        HapticService.medium()
                        onDelete()
                    } label: {
                        Text("Delete")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
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
        .accessibilityAddTraits(.isModal)
    }
}
