import XCTest
@testable import BeachPang

/// Port of the web game's board.test.ts suite.
final class BoardLogicTests: XCTestCase {

    // MARK: - Helpers

    /// Deterministic LCG matching the web test suite's makeRng.
    private func makeRng(seed: Int) -> Rng {
        var state = seed
        return {
            state = (state * 1103515245 + 12345) % 2147483648
            return Double(state) / 2147483648
        }
    }

    private func makeIdGen() -> NextId {
        var id = 0
        return {
            id += 1
            return id
        }
    }

    /// Builds a board from kind digits; 8x8, no specials. `overrides` can
    /// attach specials at positions.
    private func boardFromKinds(
        _ rows: [[Int]],
        overrides: [(row: Int, col: Int, special: SpecialKind)] = []
    ) -> BoardGrid {
        var id = 0
        var board: BoardGrid = rows.map { row in
            row.map { kind in
                id += 1
                return Tile(id: id, kind: kind, special: nil)
            }
        }
        for (row, col, special) in overrides {
            board[row][col]?.special = special
        }
        return board
    }

    /// kind(r, c) = (floor(c/2) + 2r) % 5 — horizontal pairs, vertical stride
    /// of 2 mod 5, so the base grid contains no 3-run in any direction.
    private func noMatchGrid() -> [[Int]] {
        (0..<BoardSpec.rows).map { row in
            (0..<BoardSpec.cols).map { col in
                (col / 2 + row * 2) % BoardSpec.kindCount
            }
        }
    }

    // MARK: - createBoard

    func testCreateBoardIsFullWithNoPremadeMatchesAndAValidMove() {
        for seed in 1...10 {
            let board = createBoard(rng: makeRng(seed: seed), nextId: makeIdGen())
            XCTAssertEqual(board.count, BoardSpec.rows)
            for row in board {
                XCTAssertEqual(row.count, BoardSpec.cols)
                for tile in row { XCTAssertNotNil(tile) }
            }
            XCTAssertTrue(findMatchGroups(board).isEmpty)
            XCTAssertTrue(hasValidMove(board))
        }
    }

    func testCreateBoardAssignsUniqueIds() {
        let board = createBoard(rng: makeRng(seed: 7), nextId: makeIdGen())
        let ids = board.flatMap { $0 }.map { $0!.id }
        XCTAssertEqual(Set(ids).count, BoardSpec.rows * BoardSpec.cols)
    }

    // MARK: - findMatchGroups

    func testDetectsHorizontalRunOf3WithoutSpecial() {
        var grid = noMatchGrid()
        grid[3][2] = 4; grid[3][3] = 4; grid[3][4] = 4
        let groups = findMatchGroups(boardFromKinds(grid))
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].cells.count, 3)
        XCTAssertNil(groups[0].make)
    }

    func testCreatesRocketFromRunOf4() {
        var grid = noMatchGrid()
        grid[5][1] = 4; grid[5][2] = 4; grid[5][3] = 4; grid[5][4] = 4
        let groups = findMatchGroups(boardFromKinds(grid))
        XCTAssertEqual(groups.count, 1)
        // Horizontal 4-run makes a rocket that clears its column.
        XCTAssertEqual(groups[0].make?.special, .rocketV)
    }

    func testCreatesPrismFromRunOf5Plus() {
        var grid = noMatchGrid()
        // Row 2 starts as [4,4,0,0,1,1,2,2]; extending cols 1-5 makes a 6-run.
        for col in 1...5 { grid[2][col] = 4 }
        let groups = findMatchGroups(boardFromKinds(grid))
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].cells.count, 6)
        XCTAssertEqual(groups[0].make?.special, .prism)
    }

    func testCreatesBombFromCrossingRuns() {
        var grid = noMatchGrid()
        // T shape of kind 3: horizontal row 2 cols 3-5, vertical col 4 rows 2-4.
        grid[2][3] = 3; grid[2][4] = 3; grid[2][5] = 3
        grid[4][4] = 3 // row 3 col 4 is already 3 in the base pattern
        let groups = findMatchGroups(boardFromKinds(grid))
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].cells.count, 5)
        XCTAssertEqual(groups[0].make?.special, .bomb)
    }

    func testPlacesSpecialAtPreferredSwappedCellWhenPossible() {
        var grid = noMatchGrid()
        grid[5][1] = 4; grid[5][2] = 4; grid[5][3] = 4; grid[5][4] = 4
        let groups = findMatchGroups(boardFromKinds(grid), preferred: Pos(row: 5, col: 4))
        XCTAssertEqual(groups[0].make?.pos, Pos(row: 5, col: 4))
    }

    func testDoesNotMatchPrismTilesByColor() {
        var grid = noMatchGrid()
        grid[3][2] = 4; grid[3][3] = 4; grid[3][4] = 4
        let board = boardFromKinds(grid, overrides: [(row: 3, col: 3, special: .prism)])
        XCTAssertTrue(findMatchGroups(board).isEmpty)
    }

    // MARK: - clearGroups

    func testRemovesMatchedTilesAndKeepsSpecialMakeCell() {
        var grid = noMatchGrid()
        grid[5][1] = 4; grid[5][2] = 4; grid[5][3] = 4; grid[5][4] = 4
        let board = boardFromKinds(grid)
        let groups = findMatchGroups(board, preferred: Pos(row: 5, col: 2))
        let step = clearGroups(board, groups: groups)
        XCTAssertEqual(step.cleared.count, 3)
        XCTAssertEqual(step.board[5][2]?.special, .rocketV)
        XCTAssertNil(step.board[5][1])
        XCTAssertNil(step.board[5][3])
        XCTAssertNil(step.board[5][4])
    }

    func testChainsSpecialsCaughtInTheBlast() {
        var grid = noMatchGrid()
        grid[3][2] = 4; grid[3][3] = 4; grid[3][4] = 4
        // A rocket sitting inside the matched run detonates and clears its row.
        let board = boardFromKinds(grid, overrides: [(row: 3, col: 2, special: .rocketH)])
        let groups = findMatchGroups(board)
        let step = clearGroups(board, groups: groups)
        let clearedKeys = Set(step.cleared.map(posKey))
        for col in 0..<BoardSpec.cols {
            XCTAssertTrue(clearedKeys.contains(posKey(Pos(row: 3, col: col))))
        }
    }

    // MARK: - activateSpecial

    func testClearsFullRowForHorizontalRocket() {
        let board = boardFromKinds(noMatchGrid(), overrides: [(row: 4, col: 4, special: .rocketH)])
        let step = activateSpecial(board, at: Pos(row: 4, col: 4))
        XCTAssertEqual(step.cleared.count, BoardSpec.cols)
        for col in 0..<BoardSpec.cols { XCTAssertNil(step.board[4][col]) }
    }

    func testClears5x5AreaForBombClippedAtEdges() {
        let board = boardFromKinds(noMatchGrid(), overrides: [(row: 0, col: 0, special: .bomb)])
        let step = activateSpecial(board, at: Pos(row: 0, col: 0))
        // 5×5 blast at corner (0,0) clips to rows 0..2, cols 0..2 → 9 cells.
        XCTAssertEqual(step.cleared.count, 9)
        for row in 0...2 { for col in 0...2 { XCTAssertNil(step.board[row][col]) } }
        for row in 3..<BoardSpec.rows { for col in 0..<BoardSpec.cols {
            XCTAssertNotNil(step.board[row][col])
        } }
    }

    func testDoesNothingForANormalTile() {
        let board = boardFromKinds(noMatchGrid())
        let step = activateSpecial(board, at: Pos(row: 2, col: 2))
        XCTAssertTrue(step.cleared.isEmpty)
    }

    // MARK: - activatePrismSwap

    func testClearsEveryTileOfSwappedKindPlusPrism() {
        let grid = noMatchGrid()
        let board = boardFromKinds(grid, overrides: [(row: 4, col: 4, special: .prism)])
        let otherKind = grid[4][5]
        // The prism cell itself is counted in the grid tally but cleared as
        // the prism, so totals match exactly.
        let expected = grid.flatMap { $0 }.filter { $0 == otherKind }.count
        let step = activatePrismSwap(board, prismPos: Pos(row: 4, col: 4), otherPos: Pos(row: 4, col: 5))
        XCTAssertEqual(step.cleared.count, expected)
        XCTAssertNil(step.board[4][4])
        XCTAssertNil(step.board[4][5])
    }

    // MARK: - gravity and refill

    func testGravityDropsTilesPreservingOrderAndIdentity() {
        var board = boardFromKinds(noMatchGrid())
        let falling = board[0][3]!
        board[6][3] = nil
        board[4][3] = nil
        let next = applyGravity(board)
        XCTAssertNil(next[0][3])
        XCTAssertNil(next[1][3])
        XCTAssertEqual(next[2][3]?.id, falling.id)
        for row in 2..<BoardSpec.rows { XCTAssertNotNil(next[row][3]) }
    }

    func testRefillFillsEveryEmptyCellWithFreshTiles() {
        var board = boardFromKinds(noMatchGrid())
        board[0][0] = nil
        board[5][7] = nil
        let next = refill(board, rng: makeRng(seed: 3), nextId: makeIdGen())
        for row in next {
            for tile in row { XCTAssertNotNil(tile) }
        }
    }

    // MARK: - hasValidMove / shuffleBoard

    func testHasValidMoveMatchesExhaustiveCheck() {
        let board = boardFromKinds(noMatchGrid())
        // The striped pattern may still have moves; verify via exhaustive
        // check against findMatchGroups on every swap.
        var expected = false
        outer: for row in 0..<BoardSpec.rows {
            for col in 0..<BoardSpec.cols {
                for (dr, dc) in [(0, 1), (1, 0)] {
                    let r2 = row + dr
                    let c2 = col + dc
                    if r2 >= BoardSpec.rows || c2 >= BoardSpec.cols { continue }
                    let swapped = swapTiles(board, Pos(row: row, col: col), Pos(row: r2, col: c2))
                    if !findMatchGroups(swapped).isEmpty {
                        expected = true
                        break outer
                    }
                }
            }
        }
        XCTAssertEqual(hasValidMove(board), expected)
    }

    func testTreatsAnySpecialTileAsAValidMove() {
        let board = boardFromKinds(noMatchGrid(), overrides: [(row: 0, col: 0, special: .bomb)])
        XCTAssertTrue(hasValidMove(board))
    }

    func testShuffleKeepsSameTileMultisetAndYieldsPlayableBoard() {
        let board = createBoard(rng: makeRng(seed: 11), nextId: makeIdGen())
        let before = board.flatMap { $0 }.map { $0!.id }.sorted()
        let next = shuffleBoard(board, rng: makeRng(seed: 12))
        let after = next.flatMap { $0 }.map { $0!.id }.sorted()
        XCTAssertEqual(after, before)
        XCTAssertTrue(findMatchGroups(next).isEmpty)
        XCTAssertTrue(hasValidMove(next))
    }

    // MARK: - level rules

    func testLevelRules() {
        XCTAssertEqual(LevelRules.levelTarget(1), 1000)
        XCTAssertEqual(LevelRules.levelTarget(3), 2500)
        XCTAssertEqual(LevelRules.cascadeMultiplier(0), 1)
        XCTAssertEqual(LevelRules.cascadeMultiplier(9), 5)
        XCTAssertEqual(LevelRules.clearScore(clearedCount: 3, cascade: 0), 180)
        XCTAssertEqual(LevelRules.starsForScore(999, target: 1000), 0)
        XCTAssertEqual(LevelRules.starsForScore(1000, target: 1000), 1)
        XCTAssertEqual(LevelRules.starsForScore(1500, target: 1000), 2)
        XCTAssertEqual(LevelRules.starsForScore(2000, target: 1000), 3)
    }
}
