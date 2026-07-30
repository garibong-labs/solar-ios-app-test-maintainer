# PR #4 Test Failure Summary

## Command

```bash
xcodebuild test -project BeachPang.xcodeproj -scheme BeachPang -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'
```

## Result

The PR branch failed one existing unit test:

- `BoardLogicTests.testClears3x3AreaForBombClippedAtEdges()`

## Cause

PR #4 changes bomb blast coverage from a 3x3 area to a 5x5 area in `BeachPang/Game/BoardLogic.swift`.

The production code clips the blast to board bounds correctly, but the test still expected the old 3x3 behavior. A bomb at the top-left corner now clears the clipped 5x5 area:

- old 3x3 clipped at `(0, 0)`: `2 * 2 = 4` cells
- new 5x5 clipped at `(0, 0)`: `3 * 3 = 9` cells

## Fix

Updated the bomb tests to match the new 5x5 behavior:

- Added a centered bomb assertion for 25 cleared cells.
- Renamed the edge clipping test from 3x3 to 5x5.
- Updated the top-left clipped expectation from 4 to 9 cleared cells.
