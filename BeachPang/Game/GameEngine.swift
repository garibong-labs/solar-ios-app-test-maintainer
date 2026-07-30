import Foundation
import Observation

enum GamePhase {
    case idle, busy, won, lost
}

struct Burst: Identifiable, Equatable {
    let id: Int
    let row: Int
    let col: Int
    let kind: Int
}

struct ComboPopup: Identifiable, Equatable {
    let id: Int
    let multiplier: Int
}

@MainActor
@Observable
final class GameEngine {
    private(set) var board: BoardGrid
    private(set) var level: Int
    private(set) var score = 0
    private(set) var movesLeft = LevelRules.movesPerLevel
    private(set) var phase: GamePhase = .idle
    private(set) var bestScore: Int
    private(set) var unlocked: Int
    private(set) var starsByStage: [Int: Int]
    private(set) var earnedStars = 0
    private(set) var winBonus = 0
    private(set) var clearingIds: Set<Int> = []
    private(set) var newTileIds: Set<Int> = []
    private(set) var bursts: [Burst] = []
    private(set) var combo: ComboPopup?
    private(set) var shuffleNotice = false

    var target: Int { LevelRules.levelTarget(level) }

    private var progress: GameProgress
    private var lastId = 0
    private var pendingTasks: [Task<Void, Never>] = []

    private static let swapDelay: Duration = .milliseconds(200)
    private static let clearDelay: Duration = .milliseconds(300)
    private static let fallDelay: Duration = .milliseconds(340)
    private static let burstDelay: Duration = .milliseconds(650)
    private static let maxBurstsPerStep = 14

    init() {
        let saved = ProgressStore.load()
        progress = saved
        level = saved.level
        bestScore = saved.bestScore
        unlocked = saved.level
        starsByStage = saved.stars
        board = [] // replaced just below; createBoard needs nextId on self
        board = createBoard(rng: { Double.random(in: 0..<1) }, nextId: nextId)
    }

    private func nextId() -> Int {
        lastId += 1
        return lastId
    }

    private func schedule(after delay: Duration, _ fn: @escaping @MainActor () -> Void) {
        let task = Task { @MainActor in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            fn()
        }
        pendingTasks.append(task)
    }

    private func cancelPending() {
        for task in pendingTasks { task.cancel() }
        pendingTasks = []
    }

    // MARK: - Moves

    func swap(_ a: Pos, _ b: Pos) {
        guard phase == .idle, movesLeft > 0, isAdjacent(a, b),
              let tileA = board[a.row][a.col],
              let tileB = board[b.row][b.col]
        else { return }

        let swapped = swapTiles(board, a, b)
        phase = .busy
        board = swapped

        schedule(after: Self.swapDelay) { [self] in
            let aIsPrism = tileA.special == .prism
            let bIsPrism = tileB.special == .prism
            if aIsPrism || bIsPrism {
                consumeMove()
                // After the swap, tileA sits at b and tileB sits at a.
                let prismPos = aIsPrism ? b : a
                let otherPos = aIsPrism ? a : b
                let step = (aIsPrism && bIsPrism)
                    ? clearAll(swapped)
                    : activatePrismSwap(swapped, prismPos: prismPos, otherPos: otherPos)
                playClearStep(prevBoard: swapped, step: step, cascade: 0)
                return
            }

            let groups = findMatchGroups(swapped, preferred: b)
            if groups.isEmpty {
                let original = swapTiles(swapped, a, b)
                board = original
                schedule(after: Self.swapDelay) { [self] in phase = .idle }
                return
            }
            consumeMove()
            playClearStep(prevBoard: swapped, step: clearGroups(swapped, groups: groups), cascade: 0)
        }
    }

    func tapSpecial(at pos: Pos) {
        guard phase == .idle, movesLeft > 0,
              let tile = board[pos.row][pos.col], tile.special != nil
        else { return }
        phase = .busy
        consumeMove()
        playClearStep(prevBoard: board, step: activateSpecial(board, at: pos), cascade: 0)
    }

    // MARK: - Level flow

    func goNextLevel() { startLevel(level + 1) }

    func retryLevel() { startLevel(level) }

    func playStage(_ stage: Int) {
        guard stage >= 1, stage <= progress.level else { return }
        startLevel(stage)
    }

    private func startLevel(_ nextLevel: Int) {
        cancelPending()
        level = nextLevel
        score = 0
        movesLeft = LevelRules.movesPerLevel
        winBonus = 0
        earnedStars = 0
        clearingIds = []
        newTileIds = []
        bursts = []
        combo = nil
        shuffleNotice = false
        board = createBoard(rng: { Double.random(in: 0..<1) }, nextId: nextId)
        phase = .idle
    }

    // MARK: - Internals

    private func consumeMove() {
        movesLeft = max(0, movesLeft - 1)
    }

    private func playClearStep(prevBoard: BoardGrid, step: ClearStep, cascade: Int) {
        let makeKeys = Set(step.makes.map(posKey))
        var ids = Set<Int>()
        var stepBursts: [Burst] = []
        for pos in step.cleared {
            if makeKeys.contains(posKey(pos)) { continue }
            guard let tile = prevBoard[pos.row][pos.col] else { continue }
            ids.insert(tile.id)
            if stepBursts.count < Self.maxBurstsPerStep {
                stepBursts.append(Burst(id: tile.id, row: pos.row, col: pos.col, kind: tile.kind))
            }
        }

        score += LevelRules.clearScore(clearedCount: step.cleared.count, cascade: cascade)
        clearingIds = ids
        bursts.append(contentsOf: stepBursts)
        schedule(after: Self.burstDelay) { [self] in
            bursts.removeAll { ids.contains($0.id) }
        }
        if cascade >= 1 {
            combo = ComboPopup(id: nextId(), multiplier: min(cascade + 1, 5))
            schedule(after: .milliseconds(900)) { [self] in combo = nil }
        }

        schedule(after: Self.clearDelay) { [self] in
            clearingIds = []
            let fallen = applyGravity(step.board)
            let lastIdBeforeRefill = lastId
            let filled = refill(fallen, rng: { Double.random(in: 0..<1) }, nextId: nextId)
            var fresh = Set<Int>()
            for row in filled {
                for tile in row {
                    if let tile, tile.id > lastIdBeforeRefill { fresh.insert(tile.id) }
                }
            }
            newTileIds = fresh
            board = filled
            schedule(after: Self.fallDelay) { [self] in
                let groups = findMatchGroups(filled)
                if !groups.isEmpty {
                    playClearStep(
                        prevBoard: filled,
                        step: clearGroups(filled, groups: groups),
                        cascade: cascade + 1
                    )
                } else {
                    settle(filled)
                }
            }
        }
    }

    private func settle(_ currentBoard: BoardGrid) {
        let stage = level
        let target = LevelRules.levelTarget(stage)
        if score >= target {
            let bonus = movesLeft * LevelRules.moveBonus
            winBonus = bonus
            score += bonus
            let stars = LevelRules.starsForScore(score, target: target)
            var nextStars = progress.stars
            nextStars[stage] = max(nextStars[stage] ?? 0, stars)
            progress = GameProgress(
                level: max(progress.level, stage + 1),
                bestScore: max(progress.bestScore, score),
                stars: nextStars
            )
            ProgressStore.save(progress)
            bestScore = progress.bestScore
            unlocked = progress.level
            starsByStage = nextStars
            earnedStars = stars
            phase = .won
            return
        }
        if movesLeft <= 0 {
            phase = .lost
            return
        }
        if !hasValidMove(currentBoard) {
            board = shuffleBoard(currentBoard, rng: { Double.random(in: 0..<1) })
            shuffleNotice = true
            schedule(after: .milliseconds(1800)) { [self] in shuffleNotice = false }
        }
        phase = .idle
    }
}
