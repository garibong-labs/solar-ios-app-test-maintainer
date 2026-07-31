import Foundation

private func randomKind(_ rng: Rng) -> Int {
    min(Int(rng() * Double(BoardSpec.kindCount)), BoardSpec.kindCount - 1)
}

private func tileAt(_ board: BoardGrid, _ pos: Pos) -> Tile? {
    inBounds(pos.row, pos.col) ? board[pos.row][pos.col] : nil
}

/// Prism tiles have no matchable color; every other tile matches by kind.
private func matchKind(_ tile: Tile?) -> Int? {
    guard let tile, tile.special != .prism else { return nil }
    return tile.kind
}

func createBoard(rng: Rng, nextId: NextId) -> BoardGrid {
    for _ in 0..<50 {
        var board: BoardGrid = Array(
            repeating: Array(repeating: nil, count: BoardSpec.cols),
            count: BoardSpec.rows
        )
        for row in 0..<BoardSpec.rows {
            for col in 0..<BoardSpec.cols {
                var kind = randomKind(rng)
                // Avoid spawning an immediate 3-run with the two tiles left/above.
                for _ in 0..<BoardSpec.kindCount {
                    let left2 = col >= 2
                        && board[row][col - 1]?.kind == kind
                        && board[row][col - 2]?.kind == kind
                    let up2 = row >= 2
                        && board[row - 1][col]?.kind == kind
                        && board[row - 2][col]?.kind == kind
                    if !left2 && !up2 { break }
                    kind = (kind + 1) % BoardSpec.kindCount
                }
                board[row][col] = Tile(id: nextId(), kind: kind, special: nil)
            }
        }
        if hasValidMove(board) { return board }
    }
    fatalError("createBoard: could not produce a playable board")
}

private struct Run {
    var cells: [Pos]
    var horizontal: Bool
}

private func findRuns(_ board: BoardGrid) -> [Run] {
    var runs: [Run] = []
    for row in 0..<BoardSpec.rows {
        var start = 0
        while start < BoardSpec.cols {
            let kind = matchKind(board[row][start])
            var end = start + 1
            while end < BoardSpec.cols, kind != nil, matchKind(board[row][end]) == kind {
                end += 1
            }
            if kind != nil, end - start >= 3 {
                runs.append(Run(
                    cells: (start..<end).map { Pos(row: row, col: $0) },
                    horizontal: true
                ))
            }
            start = end
        }
    }
    for col in 0..<BoardSpec.cols {
        var start = 0
        while start < BoardSpec.rows {
            let kind = matchKind(board[start][col])
            var end = start + 1
            while end < BoardSpec.rows, kind != nil, matchKind(board[end][col]) == kind {
                end += 1
            }
            if kind != nil, end - start >= 3 {
                runs.append(Run(
                    cells: (start..<end).map { Pos(row: $0, col: col) },
                    horizontal: false
                ))
            }
            start = end
        }
    }
    return runs
}

/// Finds match groups (runs merged when they share a cell) and decides which
/// special tile each group produces:
/// - run of 5+          -> prism
/// - crossing runs      -> bomb
/// - run of 4           -> rocket (horizontal run clears its column, vertical
///                         run clears its row, so the blast crosses the run)
/// `preferred` biases where the special appears (the swapped cell).
func findMatchGroups(_ board: BoardGrid, preferred: Pos? = nil) -> [MatchGroup] {
    let runs = findRuns(board)
    var groups: [[Run]] = []
    var groupOf: [Int: Int] = [:]

    for run in runs {
        var touching = Set<Int>()
        for cell in run.cells {
            if let g = groupOf[posKey(cell)] { touching.insert(g) }
        }
        let target: Int
        if touching.isEmpty {
            target = groups.count
            groups.append([])
        } else {
            let sorted = touching.sorted()
            target = sorted[0]
            for other in sorted.dropFirst() {
                for moved in groups[other] {
                    groups[target].append(moved)
                    for cell in moved.cells { groupOf[posKey(cell)] = target }
                }
                groups[other] = []
            }
        }
        groups[target].append(run)
        for cell in run.cells { groupOf[posKey(cell)] = target }
    }

    return groups
        .filter { !$0.isEmpty }
        .map { groupRuns in
            var seen = Set<Int>()
            var cells: [Pos] = []
            for run in groupRuns {
                for cell in run.cells where !seen.contains(posKey(cell)) {
                    seen.insert(posKey(cell))
                    cells.append(cell)
                }
            }

            let longest = groupRuns.max { $0.cells.count < $1.cells.count }!
            var special: SpecialKind?
            if longest.cells.count >= 5 {
                special = .prism
            } else if groupRuns.count > 1 {
                special = .bomb
            } else if longest.cells.count == 4 {
                special = longest.horizontal ? .rocketV : .rocketH
            }

            var make: (pos: Pos, special: SpecialKind)?
            if let special {
                let preferredCell = preferred.flatMap { seen.contains(posKey($0)) ? $0 : nil }
                let pos = preferredCell ?? longest.cells[longest.cells.count / 2]
                make = (pos: pos, special: special)
            }
            return MatchGroup(cells: cells, make: make)
        }
}

private func mostCommonKind(_ board: BoardGrid) -> Int {
    var counts = Array(repeating: 0, count: BoardSpec.kindCount)
    for row in board {
        for tile in row {
            if let tile, tile.special != .prism { counts[tile.kind] += 1 }
        }
    }
    var best = 0
    for kind in 1..<BoardSpec.kindCount where counts[kind] > counts[best] {
        best = kind
    }
    return best
}

private func specialBlast(_ board: BoardGrid, _ pos: Pos, _ special: SpecialKind) -> [Pos] {
    var cells: [Pos] = []
    switch special {
    case .rocketH:
        for col in 0..<BoardSpec.cols { cells.append(Pos(row: pos.row, col: col)) }
    case .rocketV:
        for row in 0..<BoardSpec.rows { cells.append(Pos(row: row, col: pos.col)) }
    case .bomb:
        for row in (pos.row - 2)...(pos.row + 2) {
            for col in (pos.col - 2)...(pos.col + 2) where inBounds(row, col) {
                cells.append(Pos(row: row, col: col))
            }
        }
    case .prism:
        let kind = mostCommonKind(board)
        cells.append(pos)
        for row in 0..<BoardSpec.rows {
            for col in 0..<BoardSpec.cols {
                if let tile = board[row][col], tile.special != .prism, tile.kind == kind {
                    cells.append(Pos(row: row, col: col))
                }
            }
        }
    }
    return cells
}

/// Expands `seeds` into the full set of cleared cells, chaining specials:
/// any special tile caught in the blast detonates too.
func collectClearSet(
    _ board: BoardGrid,
    seeds: [Pos],
    protectedKeys: Set<Int> = []
) -> Set<Int> {
    var cleared = Set<Int>()
    var queue = seeds
    while let pos = queue.popLast() {
        let key = posKey(pos)
        if cleared.contains(key) || protectedKeys.contains(key) { continue }
        guard let tile = tileAt(board, pos) else { continue }
        cleared.insert(key)
        if let special = tile.special {
            queue.append(contentsOf: specialBlast(board, pos, special))
        }
    }
    return cleared
}

private func keyToPos(_ key: Int) -> Pos {
    Pos(row: key / BoardSpec.cols, col: key % BoardSpec.cols)
}

/// Clears all matched groups at once: cells vanish, and the "make" cell of
/// each group turns into its special tile instead of clearing.
func clearGroups(_ board: BoardGrid, groups: [MatchGroup]) -> ClearStep {
    let makes = groups.compactMap(\.make)
    let protectedKeys = Set(makes.map { posKey($0.pos) })
    let seeds = groups.flatMap(\.cells)
    let clearedKeys = collectClearSet(board, seeds: seeds, protectedKeys: protectedKeys)

    var next = board
    for key in clearedKeys {
        let pos = keyToPos(key)
        next[pos.row][pos.col] = nil
    }
    for (pos, special) in makes {
        if var tile = next[pos.row][pos.col] {
            tile.special = special
            next[pos.row][pos.col] = tile
        }
    }
    return ClearStep(
        board: next,
        cleared: clearedKeys.map(keyToPos),
        makes: makes.map(\.pos)
    )
}

/// Detonates the special tile at `pos` (tap-to-activate).
func activateSpecial(_ board: BoardGrid, at pos: Pos) -> ClearStep {
    guard let tile = tileAt(board, pos), tile.special != nil else {
        return ClearStep(board: board, cleared: [], makes: [])
    }
    let clearedKeys = collectClearSet(board, seeds: [pos])
    var next = board
    for key in clearedKeys {
        let p = keyToPos(key)
        next[p.row][p.col] = nil
    }
    return ClearStep(board: next, cleared: clearedKeys.map(keyToPos), makes: [])
}

/// Swapping a prism with a normal tile clears every tile of that kind
/// (plus the prism itself).
func activatePrismSwap(_ board: BoardGrid, prismPos: Pos, otherPos: Pos) -> ClearStep {
    guard let other = tileAt(board, otherPos) else {
        return ClearStep(board: board, cleared: [], makes: [])
    }
    var seeds: [Pos] = []
    for row in 0..<BoardSpec.rows {
        for col in 0..<BoardSpec.cols {
            if let tile = board[row][col], tile.special != .prism, tile.kind == other.kind {
                seeds.append(Pos(row: row, col: col))
            }
        }
    }
    // Chain specials hit by the sweep, but the prism itself just vanishes —
    // it already spent its power on the chosen kind.
    var clearedKeys = collectClearSet(board, seeds: seeds, protectedKeys: [posKey(prismPos)])
    clearedKeys.insert(posKey(prismPos))
    var next = board
    for key in clearedKeys {
        let p = keyToPos(key)
        next[p.row][p.col] = nil
    }
    return ClearStep(board: next, cleared: clearedKeys.map(keyToPos), makes: [])
}

/// Swapping two prisms wipes the whole board.
func clearAll(_ board: BoardGrid) -> ClearStep {
    var cleared: [Pos] = []
    var next = board
    for row in 0..<BoardSpec.rows {
        for col in 0..<BoardSpec.cols where next[row][col] != nil {
            next[row][col] = nil
            cleared.append(Pos(row: row, col: col))
        }
    }
    return ClearStep(board: next, cleared: cleared, makes: [])
}

func swapTiles(_ board: BoardGrid, _ a: Pos, _ b: Pos) -> BoardGrid {
    var next = board
    let tmp = next[a.row][a.col]
    next[a.row][a.col] = next[b.row][b.col]
    next[b.row][b.col] = tmp
    return next
}

/// Drops tiles into empty cells below them. Tile identities are preserved.
func applyGravity(_ board: BoardGrid) -> BoardGrid {
    var next: BoardGrid = Array(
        repeating: Array(repeating: nil, count: BoardSpec.cols),
        count: BoardSpec.rows
    )
    for col in 0..<BoardSpec.cols {
        var write = BoardSpec.rows - 1
        for row in stride(from: BoardSpec.rows - 1, through: 0, by: -1) {
            if let tile = board[row][col] {
                next[write][col] = tile
                write -= 1
            }
        }
    }
    return next
}

/// Fills remaining empty cells with fresh random tiles.
func refill(_ board: BoardGrid, rng: Rng, nextId: NextId) -> BoardGrid {
    var next = board
    for row in 0..<BoardSpec.rows {
        for col in 0..<BoardSpec.cols where next[row][col] == nil {
            next[row][col] = Tile(id: nextId(), kind: randomKind(rng), special: nil)
        }
    }
    return next
}

func hasValidMove(_ board: BoardGrid) -> Bool {
    for row in board {
        for tile in row where tile?.special != nil { return true }
    }
    for row in 0..<BoardSpec.rows {
        for col in 0..<BoardSpec.cols {
            for (dr, dc) in [(0, 1), (1, 0)] {
                let other = Pos(row: row + dr, col: col + dc)
                if !inBounds(other.row, other.col) { continue }
                let swapped = swapTiles(board, Pos(row: row, col: col), other)
                if !findRuns(swapped).isEmpty { return true }
            }
        }
    }
    return false
}

/// Reshuffles tile positions until the board has a valid move and no
/// pre-made match. Falls back to the last shuffle if none is found.
func shuffleBoard(_ board: BoardGrid, rng: Rng) -> BoardGrid {
    var result = board
    for _ in 0..<50 {
        var tiles: [Tile] = []
        for row in board { for tile in row { if let tile { tiles.append(tile) } } }
        if tiles.count > 1 {
            for i in stride(from: tiles.count - 1, to: 0, by: -1) {
                let j = min(Int(rng() * Double(i + 1)), i)
                tiles.swapAt(i, j)
            }
        }
        var next = board
        var index = 0
        for row in 0..<BoardSpec.rows {
            for col in 0..<BoardSpec.cols where next[row][col] != nil {
                next[row][col] = tiles[index]
                index += 1
            }
        }
        result = next
        if findRuns(next).isEmpty && hasValidMove(next) { return next }
    }
    return result
}
