# solar-ios-app-test-maintainer

> Solar 기반 OpenClaw 에이전트의 iOS 프로젝트 테스트 실패 자동 복구 실험

## 개요

BeachPang은 SwiftUI로 작성된 네이티브 iOS 매치-3 게임입니다. 이 저장소는 프로덕션 코드만 바꾸고 테스트는 갱신하지 않은 PR을 입력으로 주었을 때, Solar 기반 OpenClaw 에이전트가 테스트 실패를 진단하고 낡은 테스트를 복구한 뒤 후속 PR을 만드는지 관찰한 실험의 공개 제출물입니다. 앱 소스, 테스트, 실험에 사용된 PR들이 모두 이 저장소에 그대로 남아 있어 실험을 재현할 수 있습니다.

## Quick start

```bash
git clone https://github.com/garibong-labs/solar-ios-app-test-maintainer.git
cd solar-ios-app-test-maintainer
scripts/test.sh
```

`scripts/test.sh`는 저장소 루트가 아닌 다른 위치에서 실행해도 동작하며, 기본 시뮬레이터는 `platform=iOS Simulator,name=iPhone 17 Pro`입니다. `DESTINATION` 환경 변수로 대상을 바꿀 수 있습니다.

```bash
DESTINATION='platform=iOS Simulator,name=iPhone 17' scripts/test.sh
```

## 요구 사항

- Xcode 16 이상 (deployment target: iOS 17)
- iOS 시뮬레이터 (기본: iPhone 17 Pro)

## 저장소 구성

- `BeachPang/` — SwiftUI 앱 소스 (게임 로직과 UI)
- `BeachPangTests/` — XCTest 스위트 (`main` 기준 20개, 전부 통과)
- `BeachPang.xcodeproj` — Xcode 프로젝트 (scheme: `BeachPang`)
- `scripts/test.sh` — 테스트 실행 스크립트
- `docs/experiment.md` — 실험 설계와 프로토콜
- `docs/results.md` — 실험 결과
- `docs/demo/` — 실험 진행 화면 캡처
- `docs/BeachPang-README.md` — 원본 프로젝트 README

## 실험 PR

- 입력 PR #4 — 폭탄 폭발 반경을 3×3에서 5×5로 확장하는 프로덕션 전용 변경. 테스트를 갱신하지 않아 20개 중 19개만 통과하는 상태를 만든다: <https://github.com/garibong-labs/solar-ios-app-test-maintainer/pull/4>
- Solar Open 2 결과 PR #5 — 에이전트가 테스트를 복구해 20/20 통과에 도달한 후속 PR: <https://github.com/garibong-labs/solar-ios-app-test-maintainer/pull/5>
- GPT-5.5 참고 PR #6 — 별도의 정성적 참고 실행 1회 (Solar 반복 횟수에 미포함): <https://github.com/garibong-labs/solar-ios-app-test-maintainer/pull/6>

상세 설계는 [docs/experiment.md](docs/experiment.md)를 참조하세요.

## 결과 요약

- 유지보수 작업: Solar Open 2는 낡은 테스트를 정확히 진단·복구하고 20/20 테스트 통과를 재검증한 뒤 커밋·푸시까지 완료했습니다.
- PR 생성: 첫 시도는 로컬 ref `pr4`를 GitHub base 브랜치로 사용해 실패했습니다 (`Base ref must be a branch`). 최종적으로 올바른 base/head의 PR #5가 존재하지만, 사람이 상태를 확인해 주는 개입이 필요했습니다.
- 커뮤니케이션: 진행 보고가 드물었고 최종 Discord 완료 메시지는 안정적으로 전달되지 않았습니다.
- 이 실행은 조건 없는 end-to-end 성공이 아니라, 코드 유지보수에는 성공하고 오케스트레이션·커뮤니케이션에는 결함이 있었던 실행입니다.

전체 결과는 [docs/results.md](docs/results.md)를 참조하세요.

## 한계

- 유효한 Solar 독립 실행은 1회입니다. 실행 #2와 #3은 오염된 체크아웃 재사용으로 무효 처리되어 제외했습니다 (Solar의 실패 사례가 아님).
- GPT-5.5 실행은 정성적 참고 1회로, 모델 간 우열이나 통계적 유의성을 주장할 근거가 되지 않습니다.

## 출처 (Provenance)

BeachPang 앱 소스, 테스트, Xcode 프로젝트는
[Hamjoon/tile-matching-ios](https://github.com/Hamjoon/tile-matching-ios)의
커밋 `cd9789b83bc6c0f6a791c0ebd0a42f4407ff25cc`에서 수정 없이 가져왔으며,
원본 저장소의 README만 [docs/BeachPang-README.md](docs/BeachPang-README.md)로 옮겼습니다.
