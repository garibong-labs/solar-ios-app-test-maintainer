import SwiftUI

enum GameButtonVariant {
    case primary, aqua, sand
}

/// Chunky arcade button with a pressed-down "3D" edge, matching the web game.
struct GameButton: View {
    let title: String
    var variant: GameButtonVariant = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .black))
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(ArcadeButtonStyle(variant: variant))
    }
}

private struct ArcadeButtonStyle: ButtonStyle {
    let variant: GameButtonVariant

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(textColor)
            .background(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(gradient)
                    .overlay(alignment: .top) {
                        // Glossy highlight along the top edge.
                        Capsule()
                            .fill(LinearGradient(
                                colors: [.white.opacity(variant == .sand ? 0.85 : 0.5), .clear],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .frame(height: 18)
                            .padding(.horizontal, 24)
                            .padding(.top, 4)
                    }
            )
            .background(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(edgeColor)
                    .offset(y: pressed ? 1 : 5)
            )
            .offset(y: pressed ? 4 : 0)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }

    private var gradient: LinearGradient {
        switch variant {
        case .primary:
            LinearGradient(
                colors: [Color(hex: 0xFFC65C), Color(hex: 0xFF9F1C), Color(hex: 0xF57F00)],
                startPoint: .top, endPoint: .bottom
            )
        case .aqua:
            LinearGradient(
                colors: [Color(hex: 0x6FDCFF), Color(hex: 0x22A3E8), Color(hex: 0x0D7EC2)],
                startPoint: .top, endPoint: .bottom
            )
        case .sand:
            LinearGradient(
                colors: [Color(hex: 0xFFFDF4), Color(hex: 0xFFEDC4), Color(hex: 0xFFE2A6)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    private var edgeColor: Color {
        switch variant {
        case .primary: Color(hex: 0xC96A00)
        case .aqua: Color(hex: 0x085E94)
        case .sand: Color(hex: 0xDFB877)
        }
    }

    private var textColor: Color {
        switch variant {
        case .primary, .aqua: .white
        case .sand: Color(hex: 0x8A5A00)
        }
    }
}

/// Small frosted square icon button (menu, close).
struct IconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(Theme.ink)
                .frame(width: 38, height: 38)
                .background(.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.9), lineWidth: 1)
                )
                .shadow(color: Color(hex: 0x06466E).opacity(0.16), radius: 7, y: 6)
        }
        .accessibilityLabel(label)
    }
}
