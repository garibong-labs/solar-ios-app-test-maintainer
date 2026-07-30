# 비치팡 (BeachPang) — iOS

Native SwiftUI port of [Hamjoon/toss-game-tile-matching](https://github.com/Hamjoon/toss-game-tile-matching),
a beach-themed match-3 originally built as a React/TypeScript Apps in Toss miniapp.

## Game

- 8×8 board, 5 beach tile kinds (게, 불가사리, 수박, 물고기, 조개)
- Swipe or tap-tap to swap adjacent tiles; match 3+ to clear
- Specials: match-4 → 파도 로켓 (row/column), L/T shape → 비치볼 폭탄 (3×3),
  match-5 → 무지개 진주 (clears the most common kind; swap it to pick a kind,
  swap two prisms to wipe the board)
- 20 moves per level, score target grows 750 per level, 1–3 stars,
  cascade multiplier up to ×5, leftover-move bonus
- Stage select with unlock/star progress, onboarding, auto-shuffle when no
  move exists; progress persisted in `UserDefaults`

## Project layout

- `BeachPang/Game/` — pure game logic ported 1:1 from `src/game/*.ts`
  (board ops, match detection, specials, level rules, persistence) plus
  `GameEngine`, the `@Observable` port of the `useGame` hook
- `BeachPang/Views/` — SwiftUI UI (board, tiles, HUD, overlays, stage select)
- `BeachPangTests/` — XCTest port of `board.test.ts`

## Build & run

Requires Xcode 16+ (iOS 17 deployment target, iPhone portrait).

```bash
open BeachPang.xcodeproj
```

or from the command line:

```bash
xcodebuild -project BeachPang.xcodeproj -scheme BeachPang \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

xcodebuild -project BeachPang.xcodeproj -scheme BeachPang \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```
