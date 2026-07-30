import SwiftUI

private let swipeThreshold: CGFloat = 14

struct GameBoardView: View {
    let engine: GameEngine
    let disabled: Bool

    @State private var selected: Pos?
    @State private var dragConsumed = false

    var body: some View {
        GeometryReader { geo in
            let cell = geo.size.width / CGFloat(BoardSpec.cols)
            ZStack {
                boardBackground
                checkerboard(cell: cell)
                tiles(cell: cell)
                bursts(cell: cell)
                if let combo = engine.combo {
                    ComboPopupView(multiplier: combo.multiplier)
                        .id(combo.id)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                if engine.shuffleNotice {
                    shuffleToast(height: geo.size.height)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var boardBackground: some View {
        // Looking down into shallow water.
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(LinearGradient(
                colors: [Color(hex: 0x065482).opacity(0.5), Color(hex: 0x04426C).opacity(0.62)],
                startPoint: .top, endPoint: .bottom
            ))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.45), lineWidth: 1)
            )
            .shadow(color: Color(hex: 0x043458).opacity(0.35), radius: 20, y: 18)
    }

    private func checkerboard(cell: CGFloat) -> some View {
        ForEach(0..<(BoardSpec.rows * BoardSpec.cols), id: \.self) { index in
            let row = index / BoardSpec.cols
            let col = index % BoardSpec.cols
            RoundedRectangle(cornerRadius: cell * 0.24, style: .continuous)
                .fill(.white.opacity((row + col) % 2 == 0 ? 0.07 : 0.13))
                .frame(width: cell * 0.9, height: cell * 0.9)
                .position(
                    x: (CGFloat(col) + 0.5) * cell,
                    y: (CGFloat(row) + 0.5) * cell
                )
        }
    }

    private func tiles(cell: CGFloat) -> some View {
        ForEach(placedTiles, id: \.tile.id) { placed in
            TileView(
                tile: placed.tile,
                selected: selected == placed.pos,
                clearing: engine.clearingIds.contains(placed.tile.id)
            )
            .frame(width: cell * 0.88, height: cell * 0.88)
            .transition(.asymmetric(
                insertion: .offset(y: -cell * 2.5).combined(with: .opacity),
                removal: .identity
            ))
            .position(
                x: (CGFloat(placed.pos.col) + 0.5) * cell,
                y: (CGFloat(placed.pos.row) + 0.5) * cell
            )
            .animation(.easeOut(duration: 0.32), value: placed.pos)
            .zIndex(engine.clearingIds.contains(placed.tile.id) ? 3 : 2)
            .gesture(tileGesture(for: placed.pos))
            .accessibilityLabel(accessibilityLabel(for: placed.tile))
        }
        .animation(.easeOut(duration: 0.34), value: engine.newTileIds)
    }

    private var placedTiles: [(tile: Tile, pos: Pos)] {
        var result: [(tile: Tile, pos: Pos)] = []
        for row in 0..<BoardSpec.rows {
            for col in 0..<BoardSpec.cols {
                if let tile = engine.board[row][col] {
                    result.append((tile, Pos(row: row, col: col)))
                }
            }
        }
        return result
    }

    private func tileGesture(for pos: Pos) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !disabled, !dragConsumed else { return }
                let dx = value.translation.width
                let dy = value.translation.height
                guard max(abs(dx), abs(dy)) >= swipeThreshold else { return }
                dragConsumed = true
                selected = nil
                let target: Pos = abs(dx) > abs(dy)
                    ? Pos(row: pos.row, col: pos.col + (dx > 0 ? 1 : -1))
                    : Pos(row: pos.row + (dy > 0 ? 1 : -1), col: pos.col)
                if inBounds(target.row, target.col) {
                    engine.swap(pos, target)
                }
            }
            .onEnded { _ in
                let consumed = dragConsumed
                dragConsumed = false
                guard !consumed, !disabled else { return }
                handleTap(at: pos)
            }
    }

    private func handleTap(at pos: Pos) {
        guard let tile = engine.board[pos.row][pos.col] else { return }
        if tile.special != nil {
            selected = nil
            engine.tapSpecial(at: pos)
            return
        }
        if let current = selected {
            if current == pos {
                selected = nil
                return
            }
            if isAdjacent(current, pos) {
                selected = nil
                engine.swap(current, pos)
                return
            }
        }
        selected = pos
    }

    private func bursts(cell: CGFloat) -> some View {
        ForEach(engine.bursts) { burst in
            BurstView(color: Theme.kindMeta[burst.kind].color)
                .position(
                    x: (CGFloat(burst.col) + 0.5) * cell,
                    y: (CGFloat(burst.row) + 0.5) * cell
                )
                .zIndex(6)
                .allowsHitTesting(false)
        }
    }

    private func shuffleToast(height: CGFloat) -> some View {
        Text("움직일 수 있는 타일이 없어서 섞었어요")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(hex: 0x080C24).opacity(0.85))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.16), lineWidth: 1))
            .offset(y: height / 2 - 36)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .zIndex(8)
    }

    private func accessibilityLabel(for tile: Tile) -> String {
        let name = Theme.kindMeta[tile.kind].name
        switch tile.special {
        case .rocketH: return "\(name) 파도 로켓, 누르면 가로 한 줄이 터져요"
        case .rocketV: return "\(name) 파도 로켓, 누르면 세로 한 줄이 터져요"
        case .bomb: return "\(name) 비치볼 폭탄, 누르면 주변이 터져요"
        case .prism: return "\(name) 무지개 진주, 누르면 가장 많은 모양이 터져요"
        case nil: return name
        }
    }
}

/// Six sparks that fly outward and fade, colored per tile kind.
struct BurstView: View {
    let color: Color

    @State private var flying = false

    private static let offsets: [CGSize] = [
        CGSize(width: -34, height: -26),
        CGSize(width: 30, height: -34),
        CGSize(width: -38, height: 10),
        CGSize(width: 36, height: 16),
        CGSize(width: -12, height: 38),
        CGSize(width: 14, height: -42),
    ]

    var body: some View {
        ZStack {
            ForEach(0..<Self.offsets.count, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: 9, height: 9)
                    .shadow(color: .white.opacity(0.6), radius: 3)
                    .scaleEffect(flying ? 0.15 : 1)
                    .offset(flying ? Self.offsets[index] : .zero)
                    .opacity(flying ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { flying = true }
        }
    }
}

struct ComboPopupView: View {
    let multiplier: Int

    @State private var shown = false

    var body: some View {
        Text("콤보 x\(multiplier)")
            .font(.system(size: 36, weight: .black))
            .foregroundStyle(
                LinearGradient(colors: [.white, Color(hex: 0xFFD166)], startPoint: .top, endPoint: .bottom)
            )
            .shadow(color: .black.opacity(0.45), radius: 8, y: 3)
            .scaleEffect(shown ? 1 : 0.5)
            .offset(y: shown ? -30 : 0)
            .opacity(shown ? 1 : 0)
            .zIndex(7)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.spring(duration: 0.4)) { shown = true }
            }
    }
}
