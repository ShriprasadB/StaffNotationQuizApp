//
//  Theme.swift
//  StaffNotationQuizApp
//
//  Shared visual style: colors, gradient background, reusable card + button
//  styling, and haptic feedback helpers.
//

import SwiftUI

enum Theme {
    static let primary = Color(red: 0.42, green: 0.36, blue: 0.91)      // indigo
    static let primaryDark = Color(red: 0.27, green: 0.20, blue: 0.62)
    static let correct = Color(red: 0.18, green: 0.76, blue: 0.45)
    static let incorrect = Color(red: 0.95, green: 0.30, blue: 0.38)

    /// Full-screen brand gradient used behind every screen.
    static var background: LinearGradient {
        LinearGradient(
            colors: [primary, primaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let cornerRadius: CGFloat = 20
}

// MARK: - Card

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}

// MARK: - Primary button

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(Theme.primaryDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Haptics

enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
