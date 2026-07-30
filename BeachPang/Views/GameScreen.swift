import SwiftUI

struct GameScreen: View {
    @State private var engine = GameEngine()
    @State private var showStages = false
    @State private var menuOpen = false
    @State private var onboarding = !ProgressStore.hasSeenOnboarding()

    var body: some View {
        ZStack {
            Theme.beachBackground

            if showStages {
                StageSelectView(
                    unlocked: engine.unlocked,
                    current: engine.level,
                    starsByStage: engine.starsByStage,
                    onPick: { stage in
                        engine.playStage(stage)
                        showStages = false
                    },
                    onClose: { showStages = false }
                )
                .padding(18)
                .frame(maxWidth: 460)
            } else {
                playView
            }

            if menuOpen {
                GameMenuView(
                    onResume: { menuOpen = false },
                    onRetry: {
                        engine.retryLevel()
                        menuOpen = false
                    },
                    onOpenStages: {
                        menuOpen = false
                        showStages = true
                    }
                )
                .zIndex(40)
            }

            if onboarding {
                OnboardingView {
                    ProgressStore.markOnboardingSeen()
                    onboarding = false
                }
                .zIndex(50)
            }
        }
    }

    private var playView: some View {
        VStack(spacing: 14) {
            header
            hud
            board
            Spacer(minLength: 0)
            footer
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .frame(maxWidth: 460)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("비치팡")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: 0x05445E), Color(hex: 0x0369A1), Color(hex: 0x0EA5E9)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                Text("한여름 바닷가, 같은 모양 3개를 이어보세요")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.ink.opacity(0.72))
            }
            Spacer()
            HStack(spacing: 8) {
                Text("레벨 \(engine.level)")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Color(hex: 0x4A2C00))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0xFFE29A), Color(hex: 0xFFB020)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color(hex: 0xFFB020).opacity(0.35), radius: 6, y: 4)
                IconButton(systemName: "line.3.horizontal", label: "메뉴 열기") {
                    menuOpen = true
                }
            }
        }
    }

    private var hud: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("점수")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.ink.opacity(0.6))
                    Spacer()
                    Text(engine.score.formatted())
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy, value: engine.score)
                }
                progressBar
                Text("목표 \(engine.target.formatted())점")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.ink.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .hudPanel()

            VStack(spacing: 2) {
                Text("\(engine.movesLeft)")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(movesLow ? Color(hex: 0xE11D48) : Theme.ink)
                    .monospacedDigit()
                Text(movesLow ? "이동 얼마 안 남았어요" : "남은 이동")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(movesLow ? Color(hex: 0xBE123C) : Theme.ink.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(minWidth: 92)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .hudPanel()
            .accessibilityLabel("남은 이동 \(engine.movesLeft)번")
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            let progress = min(1, Double(engine.score) / Double(engine.target))
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.ink.opacity(0.14))
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color(hex: 0xFFD166), Color(hex: 0xFF9F1C)],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: max(10, geo.size.width * progress))
                    .animation(.easeOut(duration: 0.45), value: progress)
            }
        }
        .frame(height: 10)
        .accessibilityElement()
        .accessibilityLabel("목표 \(engine.target.formatted())점 중 \(engine.score.formatted())점")
    }

    private var movesLow: Bool { engine.movesLeft <= 5 }

    private var board: some View {
        ZStack {
            GameBoardView(engine: engine, disabled: engine.phase != .idle || menuOpen || onboarding)

            if engine.phase == .won {
                WinOverlay(
                    level: engine.level,
                    score: engine.score,
                    stars: engine.earnedStars,
                    winBonus: engine.winBonus,
                    onNext: { engine.goNextLevel() }
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .zIndex(10)
            }

            if engine.phase == .lost {
                LostOverlay(
                    remaining: engine.target - engine.score,
                    onRetry: { engine.retryLevel() }
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .zIndex(10)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.easeOut(duration: 0.25), value: engine.phase == .won || engine.phase == .lost)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Text("4개를 맞추면 파도 로켓, L자는 비치볼 폭탄, 5개는 무지개 진주가 생겨요. 특수 타일은 눌러서 터뜨려요.")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: 0x5A3E08).opacity(0.75))
                .multilineTextAlignment(.center)
            if engine.bestScore > 0 {
                Text("최고 점수 \(engine.bestScore.formatted())점")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Color(hex: 0xA16207))
            }
        }
    }
}

#Preview {
    GameScreen()
}
