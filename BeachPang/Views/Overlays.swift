import SwiftUI

/// Sun-bleached wooden beach-sign card used by every overlay.
struct OverlayCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .padding(.init(top: 26, leading: 22, bottom: 22, trailing: 22))
            .frame(maxWidth: 300)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white, lineWidth: 2.5)
            )
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(hex: 0xDCB277))
                    .offset(y: 7)
            )
            .shadow(color: Color(hex: 0x032846).opacity(0.5), radius: 24, y: 16)
    }
}

/// Dimmed water-blue backdrop behind overlay cards.
struct OverlayBackdrop: View {
    var body: some View {
        Color(hex: 0x032C4A).opacity(0.5)
    }
}

struct StarIcon: View {
    let filled: Bool
    var size: CGFloat = 15

    var body: some View {
        Image(systemName: filled ? "star.fill" : "star")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(filled ? Color(hex: 0xF59E0B) : Color(hex: 0x7A5A14).opacity(0.3))
    }
}

struct WinOverlay: View {
    let level: Int
    let score: Int
    let stars: Int
    let winBonus: Int
    let onNext: () -> Void

    var body: some View {
        ZStack {
            OverlayBackdrop()
            OverlayCard {
                HStack(spacing: 4) {
                    ForEach(1...3, id: \.self) { slot in
                        StarIcon(filled: stars >= slot, size: 30)
                    }
                }
                .padding(.bottom, 10)
                Text("레벨 \(level) 완료!")
                    .font(.system(size: 21, weight: .black))
                    .foregroundStyle(Theme.sandTitle)
                Text(bodyText)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.sandBody)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.bottom, 18)
                GameButton(title: "다음 레벨", action: onNext)
            }
            .padding(20)
        }
        .transition(.opacity)
    }

    private var bodyText: String {
        var text = "\(score.formatted())점 · 별 \(stars)개"
        if winBonus > 0 { text += " · 이동 보너스 +\(winBonus.formatted())" }
        return text
    }
}

struct LostOverlay: View {
    let remaining: Int
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            OverlayBackdrop()
            OverlayCard {
                Text("!")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0x94A3B8), Color(hex: 0x64748B)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color(hex: 0x64748B).opacity(0.4), radius: 10, y: 8)
                    .padding(.bottom, 12)
                Text("이동을 모두 썼어요")
                    .font(.system(size: 21, weight: .black))
                    .foregroundStyle(Theme.sandTitle)
                Text("목표까지 \(remaining.formatted())점 남았어요. 다시 해볼까요?")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.sandBody)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.bottom, 18)
                GameButton(title: "다시 도전", action: onRetry)
            }
            .padding(20)
        }
        .transition(.opacity)
    }
}

struct GameMenuView: View {
    let onResume: () -> Void
    let onRetry: () -> Void
    let onOpenStages: () -> Void

    @State private var showHelp = false

    var body: some View {
        ZStack {
            OverlayBackdrop().ignoresSafeArea()
            OverlayCard {
                if showHelp {
                    Text("조작법")
                        .font(.system(size: 21, weight: .black))
                        .foregroundStyle(Theme.sandTitle)
                    VStack(alignment: .leading, spacing: 7) {
                        helpRow("타일을 밀거나, 두 타일을 차례로 눌러 자리를 바꿔요.")
                        helpRow("같은 모양 3개를 이으면 사라지고 점수를 얻어요.")
                        helpRow("4개는 파도 로켓, L자는 비치볼 폭탄, 5개는 무지개 진주가 돼요.")
                        helpRow("특수 타일은 한 번 누르면 바로 터져요.")
                        helpRow("이동 횟수 안에 목표 점수를 채우면 성공!")
                    }
                    .padding(.vertical, 14)
                    GameButton(title: "뒤로", variant: .sand) { showHelp = false }
                } else {
                    Text("메뉴")
                        .font(.system(size: 21, weight: .black))
                        .foregroundStyle(Theme.sandTitle)
                        .padding(.bottom, 16)
                    VStack(spacing: 10) {
                        GameButton(title: "이어하기", action: onResume)
                        GameButton(title: "스테이지 선택", variant: .aqua, action: onOpenStages)
                        GameButton(title: "이 스테이지 다시하기", variant: .aqua, action: onRetry)
                        GameButton(title: "조작법", variant: .sand) { showHelp = true }
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                CloseBadgeButton(action: onResume)
                    .offset(x: 12, y: -14)
            }
            .padding(20)
        }
        .transition(.opacity)
    }

    private func helpRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
            Text(text)
        }
        .font(.system(size: 14))
        .foregroundStyle(Color(hex: 0x7A5C30))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Round red close button pinned to the card's corner.
struct CloseBadgeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0xFF8A8A), Color(hex: 0xF4504F), Color(hex: 0xD92D3A)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .clipShape(Circle())
                .overlay(Circle().stroke(.white, lineWidth: 2.5))
                .background(
                    Circle().fill(Color(hex: 0xA81F2C)).offset(y: 4)
                )
                .shadow(color: Color(hex: 0x780F19).opacity(0.4), radius: 8, y: 8)
        }
        .accessibilityLabel("닫기")
    }
}

struct OnboardingView: View {
    let onStart: () -> Void

    @State private var demoStep = false

    var body: some View {
        ZStack {
            OverlayBackdrop().ignoresSafeArea()
            OverlayCard {
                demo
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: 0x0A2540))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.bottom, 16)
                Text("같은 모양 3개를 이어보세요")
                    .font(.system(size: 21, weight: .black))
                    .foregroundStyle(Theme.sandTitle)
                Text("타일을 밀어서 자리를 바꾸면, 3개가 모인 모양은 팡! 하고 사라져요. 이동 횟수 안에 목표 점수를 채우면 성공이에요.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.sandBody)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.bottom, 18)
                GameButton(title: "시작하기", action: onStart)
            }
            .padding(20)
        }
        .transition(.opacity)
    }

    /// A crab slides down into place and completes a row of three.
    private var demo: some View {
        ZStack {
            demoTile("🐚").offset(x: 0, y: demoStep ? -23 : 23)
            demoTile("🦀").offset(x: -48, y: 23)
            demoTile("🦀").offset(x: 48, y: 23)
            demoTile("🦀")
                .offset(x: 0, y: demoStep ? 23 : -23)
                .scaleEffect(demoStep ? 1 : 1)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                demoStep = true
            }
        }
    }

    private func demoTile(_ emoji: String) -> some View {
        Text(emoji)
            .font(.system(size: 26))
            .frame(width: 44, height: 44)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0xFFFDF4), Color(hex: 0xFFEFC8), Color(hex: 0xFFE0A2)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .shadow(color: Color(hex: 0x032A48).opacity(0.42), radius: 5, y: 4)
    }
}
