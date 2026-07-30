import Foundation

enum BoardSpec {
    static let rows = 8
    static let cols = 8
    static let kindCount = 5
}

enum SpecialKind: String, Codable {
    case rocketH, rocketV, bomb, prism
}

struct Tile: Equatable, Identifiable {
    let id: Int
    var kind: Int
    var special: SpecialKind?
}

typealias BoardGrid = [[Tile?]]

struct Pos: Hashable {
    var row: Int
    var col: Int
}

/// Returns a value in [0, 1). Injectable for deterministic tests.
typealias Rng = () -> Double

typealias NextId = () -> Int

struct MatchGroup {
    var cells: [Pos]
    /// Special tile born from this group (match-4, match-5, L/T shape).
    var make: (pos: Pos, special: SpecialKind)?
}

struct ClearStep {
    var board: BoardGrid
    /// Positions whose tiles were removed in this step.
    var cleared: [Pos]
    /// Positions where a new special tile appeared.
    var makes: [Pos]
}

func posKey(_ pos: Pos) -> Int {
    pos.row * BoardSpec.cols + pos.col
}

func inBounds(_ row: Int, _ col: Int) -> Bool {
    row >= 0 && row < BoardSpec.rows && col >= 0 && col < BoardSpec.cols
}

func isAdjacent(_ a: Pos, _ b: Pos) -> Bool {
    abs(a.row - b.row) + abs(a.col - b.col) == 1
}
