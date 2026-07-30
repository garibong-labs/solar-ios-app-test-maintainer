import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

enum Theme {
    static let ink = Color(hex: 0x073B5C)
    static let sandText = Color(hex: 0x5F451A)
    static let sandTitle = Color(hex: 0x6B4A12)
    static let sandBody = Color(hex: 0x8A6A3F)

    /// One entry per tile kind: emoji face + spark color for clear bursts.
    static let kindMeta: [(name: String, emoji: String, color: Color)] = [
        ("게", "🦀", Color(hex: 0xFF4D5E)),
        ("불가사리", "⭐️", Color(hex: 0xFFB020)),
        ("수박", "🍉", Color(hex: 0x2F9E44)),
        ("물고기", "🐠", Color(hex: 0x3EC3F7)),
        ("조개", "🐚", Color(hex: 0xFF8FB3)),
    ]

    /// Midsummer beach: blazing sun, clear sky, open sea, warm sand.
    static var beachBackground: some View {
        LinearGradient(
            stops: [
                .init(color: Color(hex: 0x9FE9FF), location: 0),
                .init(color: Color(hex: 0x63D5F7), location: 0.24),
                .init(color: Color(hex: 0x2DB8E8), location: 0.44),
                .init(color: Color(hex: 0x0F97D3), location: 0.62),
                .init(color: Color(hex: 0xFFEDBC), location: 0.84),
                .init(color: Color(hex: 0xFFE0A1), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .topLeading) {
            // Morning sun glow in the upper-left sky.
            RadialGradient(
                colors: [Color(hex: 0xFFFBD6).opacity(0.95), Color(hex: 0xFFDB70).opacity(0.4), .clear],
                center: .center, startRadius: 4, endRadius: 150
            )
            .frame(width: 300, height: 300)
            .offset(x: -60, y: -80)
        }
        .ignoresSafeArea()
    }

    static var cardBackground: some ShapeStyle {
        LinearGradient(
            stops: [
                .init(color: Color(hex: 0xFFFEF8), location: 0),
                .init(color: Color(hex: 0xFFF3D6), location: 0.68),
                .init(color: Color(hex: 0xFFE9BD), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

/// Frosted-glass HUD panel used for the score and moves cards.
struct HudPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.white.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.9), lineWidth: 1)
            )
            .shadow(color: Color(hex: 0x06466E).opacity(0.16), radius: 10, y: 8)
    }
}

extension View {
    func hudPanel() -> some View { modifier(HudPanel()) }
}
