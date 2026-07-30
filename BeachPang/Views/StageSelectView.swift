import SwiftUI

private let minStages = 25
private let stageColumns = 5

struct StageSelectView: View {
    let unlocked: Int
    let current: Int
    let starsByStage: [Int: Int]
    let onPick: (Int) -> Void
    let onClose: () -> Void

    private var stageCount: Int {
        max(minStages, Int(ceil(Double(unlocked) / Double(stageColumns))) * stageColumns)
    }

    private var totalStars: Int {
        starsByStage.values.reduce(0, +)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("스테이지")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(Color(hex: 0x05445E))
                    HStack(spacing: 5) {
                        StarIcon(filled: true, size: 13)
                        Text("\(totalStars)")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(Color(hex: 0x7C4A03))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.72))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.9), lineWidth: 1))
                    .accessibilityLabel("모은 별 \(totalStars)개")
                }
                Spacer()
                IconButton(systemName: "xmark", label: "스테이지 선택 닫기", action: onClose)
            }

            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: stageColumns),
                    spacing: 10
                ) {
                    ForEach(1...stageCount, id: \.self) { stage in
                        StageCell(
                            stage: stage,
                            stars: starsByStage[stage] ?? 0,
                            isLocked: stage > unlocked,
                            isFrontier: stage == unlocked,
                            isCurrent: stage == current,
                            onPick: { onPick(stage) }
                        )
                    }
                }
            }

            GameButton(title: "돌아가기", variant: .aqua, action: onClose)
        }
    }
}

private struct StageCell: View {
    let stage: Int
    let stars: Int
    let isLocked: Bool
    let isFrontier: Bool
    let isCurrent: Bool
    let onPick: () -> Void

    var body: some View {
        Button(action: onPick) {
            ZStack {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.ink.opacity(0.4))
                } else {
                    VStack(spacing: 2) {
                        HStack(spacing: 1) {
                            ForEach(1...3, id: \.self) { slot in
                                StarIcon(filled: stars >= slot, size: 10)
                            }
                        }
                        Text("\(stage)")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(Color(hex: 0x7C4A03))
                        if isFrontier {
                            Text("도전!")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(Color(hex: 0x9A3412))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isLocked ? .white.opacity(0.65) : .white, lineWidth: isLocked ? 1 : 2)
            )
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(edgeColor)
                    .offset(y: isLocked ? 3 : 4)
            )
        }
        .disabled(isLocked)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder private var background: some View {
        if isLocked {
            LinearGradient(
                colors: [.white.opacity(0.5), .white.opacity(0.28)],
                startPoint: .top, endPoint: .bottom
            )
        } else if isFrontier {
            LinearGradient(
                colors: [Color(hex: 0xFFD876), Color(hex: 0xFFB020), Color(hex: 0xF59005)],
                startPoint: .top, endPoint: .bottom
            )
        } else {
            LinearGradient(
                colors: [Color(hex: 0xFFFDF4), Color(hex: 0xFFEDC0), Color(hex: 0xFFDF9A)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    private var edgeColor: Color {
        if isLocked { return Color(hex: 0x7A9BB4).opacity(0.35) }
        if isFrontier { return Color(hex: 0xC96A00) }
        return Color(hex: 0xDFB877)
    }

    private var accessibilityText: String {
        if isLocked { return "스테이지 \(stage), 잠김" }
        var text = "스테이지 \(stage)"
        if stars > 0 { text += ", 별 \(stars)개" }
        if isCurrent { text += ", 플레이 중" }
        return text
    }
}
