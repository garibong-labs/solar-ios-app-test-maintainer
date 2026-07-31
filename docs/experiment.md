# 실험 설계

> Solar 기반 OpenClaw 에이전트의 iOS 프로젝트 테스트 실패 자동 복구 실험

## 목적

프로덕션 코드만 바뀌고 테스트는 갱신되지 않은(stale test) PR을 입력으로 주었을 때, Solar 기반 OpenClaw 에이전트가 다음을 수행할 수 있는지 관찰한다.

1. 테스트를 실행해 실패 원인을 진단한다.
2. 낡은 테스트를 프로덕션 변경에 맞게 복구한다.
3. 복구를 재검증(전체 테스트 통과)하고 커밋한다.
4. 입력 PR 브랜치를 base로 후속 PR을 만든다.

## 대상 프로젝트

- 네이티브 SwiftUI iOS 앱: BeachPang (매치-3 게임)
- Xcode 프로젝트: `BeachPang.xcodeproj`, scheme: `BeachPang`
- Deployment target: iOS 17
- `main` 기준 baseline 테스트: XCTest 20개, 전부 통과
- 원본 소스: [Hamjoon/tile-matching-ios](https://github.com/Hamjoon/tile-matching-ios) 커밋 `cd9789b83bc6c0f6a791c0ebd0a42f4407ff25cc`에서 그대로 가져옴

## 입력 조건

- 입력 PR #4: <https://github.com/garibong-labs/solar-ios-app-test-maintainer/pull/4>
  - 브랜치: `feat/bomb-radius-5x5-reapply`
  - SHA: `51af4b2548fceaeb4d3b48a2c111df6da28839ca`
  - 폭탄(비치볼) 폭발 반경을 3×3에서 5×5로 확장하는 프로덕션 전용 변경
  - 테스트는 갱신하지 않았으므로 기대 상태는 20개 중 19개 통과(폭탄 반경 테스트 1개 실패)

## 에이전트 프롬프트

실제 사용한 프롬프트 원문이며, 기대 정답에 대한 힌트는 포함하지 않았다.

> PR을 검토하고 테스트를 실행해 실패 원인을 요약하라. 수정이 타당하다고 판단하면 구현·재검증·커밋하고, #4 브랜치를 base로 후속 PR을 만들라.

## 산출 PR

- Solar Open 2 결과 PR #5: <https://github.com/garibong-labs/solar-ios-app-test-maintainer/pull/5>
  - base: `feat/bomb-radius-5x5-reapply`, head: `update-bomb-test-for-5x5`
  - SHA: `d9eca34aa97025779068e96d33cf6f55ffcf4cdd`
  - 복구 후 20/20 테스트 통과
- GPT-5.5 참고 PR #6: <https://github.com/garibong-labs/solar-ios-app-test-maintainer/pull/6>
  - base: `feat/bomb-radius-5x5-reapply`, head: `dani/pr4-bomb-radius-test-fix`
  - SHA: `c36e0d42d84914bb09916e0e2fb93a88c3014e00`
  - 별도의 정성적 참고 실행 1회이며, Solar 반복 횟수에는 포함하지 않는다.

## 실행 프로토콜과 유효성

- 각 실행은 baseline 상태의 체크아웃에서 시작해야 유효한 독립 실행으로 인정한다.
- 실행 화면 캡처는 [demo/](demo/README.md)에 있다.
- 상세 결과는 [results.md](results.md)를 참조한다.
