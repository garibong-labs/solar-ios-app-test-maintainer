#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"

cd "$REPO_ROOT"
xcodebuild -project BeachPang.xcodeproj -scheme BeachPang -destination "$DESTINATION" test
