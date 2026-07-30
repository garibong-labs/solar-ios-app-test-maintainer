import SwiftUI

/// A single tile: warm wet-sand face carrying a beach object, or one of the
/// special faces (wave rocket, beach-ball bomb, rainbow pearl).
struct TileView: View {
    let tile: Tile
    let selected: Bool
    let clearing: Bool

    @State private var pulsing = false

    var body: some View {
        face
            .overlay(icon)
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.95), lineWidth: 3)
                        .shadow(color: Color(hex: 0xFFD166).opacity(0.8), radius: 8)
                }
            }
            .scaleEffect(clearing ? 0.1 : (pulsing ? 1.06 : 1))
            .opacity(clearing ? 0 : 1)
            .rotationEffect(.degrees(selected ? 3 : 0))
            .animation(
                selected ? .easeInOut(duration: 0.25).repeatForever(autoreverses: true) : .default,
                value: selected
            )
            .onAppear {
                if tile.special != nil {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        pulsing = true
                    }
                }
            }
    }

    @ViewBuilder private var face: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        switch tile.special {
        case .rocketH, .rocketV:
            // Wave rocket: rolling surf blues.
            shape
                .fill(LinearGradient(
                    colors: [Color(hex: 0x7FDCFF), Color(hex: 0x22A3E8), Color(hex: 0x0D67C4)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .shadow(color: Color(hex: 0x3FC3F7).opacity(0.65), radius: 6)
        case .bomb:
            shape
                .fill(RadialGradient(
                    colors: [Color(hex: 0x2E6A94), Color(hex: 0x123C5E)],
                    center: .init(x: 0.35, y: 0.28), startRadius: 2, endRadius: 40
                ))
                .shadow(color: Color(hex: 0xFF9F1C).opacity(0.6), radius: 7)
        case .prism:
            // Rainbow pearl: iridescent nacre sheen.
            shape
                .fill(RadialGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: Color(hex: 0xFFE0F0), location: 0.3),
                        .init(color: Color(hex: 0xC9F2E2), location: 0.54),
                        .init(color: Color(hex: 0xB4D8FF), location: 0.74),
                        .init(color: Color(hex: 0xDCC8FF), location: 1),
                    ],
                    center: .init(x: 0.38, y: 0.3), startRadius: 2, endRadius: 46
                ))
                .hueRotation(.degrees(pulsing ? 360 : 0))
                .shadow(color: .white.opacity(0.85), radius: 8)
        case nil:
            // Warm wet-sand face; the beach object supplies the color.
            shape
                .fill(LinearGradient(
                    colors: [Color(hex: 0xFFFDF4), Color(hex: 0xFFEFC8), Color(hex: 0xFFE0A2)],
                    startPoint: .top, endPoint: .bottom
                ))
                .overlay(
                    shape.stroke(.white.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: Color(hex: 0x032A48).opacity(0.42), radius: 4, y: 3)
        }
    }

    @ViewBuilder private var icon: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            Group {
                switch tile.special {
                case .rocketH:
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: side * 0.5, weight: .black))
                        .foregroundStyle(.white)
                case .rocketV:
                    Image(systemName: "arrow.up.and.down")
                        .font(.system(size: side * 0.5, weight: .black))
                        .foregroundStyle(.white)
                case .bomb:
                    BeachBall()
                        .frame(width: side * 0.72, height: side * 0.72)
                case .prism:
                    Image(systemName: "sparkle")
                        .font(.system(size: side * 0.5, weight: .bold))
                        .foregroundStyle(Color(hex: 0x023E66).opacity(0.5))
                case nil:
                    Text(Theme.kindMeta[tile.kind].emoji)
                        .font(.system(size: side * 0.58))
                        .shadow(color: Color(hex: 0x543006).opacity(0.28), radius: 1, y: 1)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// Six bright panels around a white cap — the classic beach ball.
struct BeachBall: View {
    private static let panels: [Color] = [
        Color(hex: 0xFF4D5E), Color(hex: 0xFFD166), Color(hex: 0x3EC3F7),
        Color(hex: 0xFF4D5E), Color(hex: 0xFFD166), Color(hex: 0x3EC3F7),
    ]

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                ForEach(0..<6, id: \.self) { index in
                    PieSlice(startDegrees: Double(index) * 60 - 90, endDegrees: Double(index + 1) * 60 - 90)
                        .fill(Self.panels[index])
                }
                Circle()
                    .stroke(Color(hex: 0x043C64).opacity(0.25), lineWidth: 1)
                Circle()
                    .fill(.white)
                    .frame(width: side * 0.3, height: side * 0.3)
                    .position(center)
            }
        }
    }
}

struct PieSlice: Shape {
    let startDegrees: Double
    let endDegrees: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startDegrees),
            endAngle: .degrees(endDegrees),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}
