// HapticService.swift
// Evapotrack
//
// Lightweight haptic feedback utility.
// Provides selection, impact, and notification haptics.
// Generators are reused per Apple's recommendation for optimal latency.

import UIKit

enum HapticService {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    static func light() {
        lightGenerator.impactOccurred()
    }

    static func medium() {
        mediumGenerator.impactOccurred()
    }

    static func success() {
        notificationGenerator.notificationOccurred(.success)
    }
}
