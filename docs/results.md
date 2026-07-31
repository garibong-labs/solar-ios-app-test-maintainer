# 실험 결과

> Solar 기반 OpenClaw 에이전트의 iOS 프로젝트 테스트 실패 자동 복구 실험

실험 설계와 입력 조건은 [experiment.md](experiment.md)를 참조한다. 결과는 하나의 성패로 뭉뚱그리지 않고 차원별로 나누어 기록한다. 이 실행을 조건 없는 end-to-end 성공으로 서술하지 않는다.

## Solar Open 2 실행 (유효 실행 1회)

### 유지보수 작업: 성공

- 입력 PR #4의 프로덕션 전용 변경(폭탄 반경 3×3 → 5×5)으로 인해 낡아진 테스트를 정확히 진단했다.
- 테스트를 5×5 반경에 맞게 복구하고 재검증하여 20/20 테스트 통과에 도달했다.
- 수정을 커밋하고 원격 브랜치 `update-bomb-test-for-5x5`로 푸시했다.

### 첫 PR 생성 시도: 실패

- GitHub base 브랜치 자리에 로컬 ref `pr4`를 사용해 PR 생성이 실패했다 (`Base ref must be a branch`).

### 복구 및 최종 상태: 부분적

- 올바른 base/head를 가진 PR #5가 존재한다: <https://github.com/garibong-labs/solar-ios-app-test-maintainer/pull/5>
- 다만 사람이 상태를 확인해 주는 개입이 필요했고, 성공한 PR 생성 경로는 캡처된 세션 기록(JSONL)에 남아 있지 않다.

### 커뮤니케이션: 미흡

- 진행 상황 보고가 드물었다.
- 최종 Discord 완료 메시지는 안정적으로 전달되지 않았다.

## GPT-5.5 참고 실행

- GPT-5.5는 동일한 유지보수 흐름을 완료하고 사람의 개입 없이 PR #6을 열었다: <https://github.com/garibong-labs/solar-ios-app-test-maintainer/pull/6>
- 단, 이는 정성적 참고 실행 1회에 불과하며 일반적인 모델 비교의 근거로는 충분하지 않다.

## 한계

- 유효한 Solar 독립 실행은 1회뿐이므로 통계적 의미를 주장할 수 없다.
- 모델 간 우열에 대한 일반화된 결론을 내리지 않는다.
- 원본 세션 기록(OpenClaw JSONL), 에이전트 내부 reasoning, 로컬 사설 경로, 비밀 정보는 공개하지 않는다.
