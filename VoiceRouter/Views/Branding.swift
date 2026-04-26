import SwiftUI

enum VoiceRouterTheme {
    static let canvasTop = Color(red: 0.04, green: 0.05, blue: 0.09)
    static let canvasMid = Color(red: 0.09, green: 0.12, blue: 0.20)
    static let canvasBottom = Color(red: 0.03, green: 0.04, blue: 0.07)

    static let textPrimary = Color(red: 0.97, green: 0.95, blue: 0.92)
    static let textSecondary = Color(red: 0.79, green: 0.80, blue: 0.84)
    static let textMuted = Color(red: 0.57, green: 0.61, blue: 0.68)

    static let coolCyan = Color(red: 0.39, green: 0.86, blue: 0.96)
    static let freshMint = Color(red: 0.55, green: 0.95, blue: 0.78)
    static let warmAmber = Color(red: 1.0, green: 0.77, blue: 0.40)
    static let softCoral = Color(red: 1.0, green: 0.46, blue: 0.35)
    static let paper = Color(red: 0.97, green: 0.94, blue: 0.87)

    static let cardFillTop = Color.white.opacity(0.08)
    static let cardFillBottom = Color.white.opacity(0.03)
    static let cardStroke = Color.white.opacity(0.10)

    static let success = Color(red: 0.36, green: 0.86, blue: 0.60)
    static let warning = Color(red: 0.99, green: 0.62, blue: 0.30)
}

struct VoiceWaveView: View {
    let level: CGFloat
    var barWidth: CGFloat = 5
    var maxHeight: CGFloat = 26
    var idleHeight: CGFloat = 8
    var colors: [Color] = [VoiceRouterTheme.coolCyan, VoiceRouterTheme.freshMint, VoiceRouterTheme.warmAmber]

    private let weights: [CGFloat] = [0.42, 0.68, 1.0, 0.78, 0.54]

    var body: some View {
        HStack(alignment: .center, spacing: barWidth * 0.55) {
            ForEach(Array(weights.enumerated()), id: \.offset) { index, weight in
                Capsule(style: .continuous)
                    .fill(colors[index % colors.count])
                    .frame(width: barWidth, height: barHeight(weight: weight, index: index))
            }
        }
        .animation(.spring(response: 0.26, dampingFraction: 0.72), value: level)
    }

    private func barHeight(weight: CGFloat, index: Int) -> CGFloat {
        let clamped = max(min(level, 1.0), 0.08)
        let base = idleHeight + (maxHeight - idleHeight) * clamped * weight
        let accent: CGFloat = index.isMultiple(of: 2) ? 2.4 : 0
        return max(idleHeight, base + accent)
    }
}

struct BrandMarkView: View {
    var size: CGFloat = 108
    var level: CGFloat = 0.12
    var isListening: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            VoiceRouterTheme.canvasMid,
                            VoiceRouterTheme.canvasTop,
                            Color.black
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(VoiceRouterTheme.coolCyan.opacity(0.28))
                .frame(width: size * 0.60, height: size * 0.60)
                .blur(radius: size * 0.11)
                .offset(x: size * 0.18, y: -size * 0.18)

            Circle()
                .fill(VoiceRouterTheme.softCoral.opacity(0.20))
                .frame(width: size * 0.46, height: size * 0.46)
                .blur(radius: size * 0.10)
                .offset(x: -size * 0.22, y: size * 0.25)

            RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)

            // Clipboard sheet
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(VoiceRouterTheme.paper)
                .frame(width: size * 0.46, height: size * 0.58)
                .rotationEffect(.degrees(-11))
                .offset(x: -size * 0.05, y: size * 0.05)
                .shadow(color: .black.opacity(0.22), radius: size * 0.06, y: size * 0.05)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "sparkle")
                        .font(.system(size: size * 0.11, weight: .bold))
                        .foregroundStyle(VoiceRouterTheme.softCoral)
                        .offset(x: size * 0.03, y: -size * 0.03)
                }

            // Dynamic-island style voice capsule
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.13, green: 0.16, blue: 0.25),
                            Color(red: 0.05, green: 0.06, blue: 0.10)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.72, height: size * 0.28)
                .shadow(
                    color: (isListening ? VoiceRouterTheme.coolCyan : VoiceRouterTheme.softCoral).opacity(0.22),
                    radius: size * 0.11,
                    y: size * 0.05
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )

            VoiceWaveView(
                level: isListening ? max(level, 0.24) : 0.16,
                barWidth: size * 0.046,
                maxHeight: size * 0.19,
                idleHeight: size * 0.06
            )
        }
        .frame(width: size, height: size)
    }
}

struct BrandLockupView: View {
    var level: CGFloat = 0.12
    var isListening: Bool = false
    var titleSize: CGFloat = 20
    var subtitle: String? = "Voice to clipboard"

    var body: some View {
        HStack(spacing: 12) {
            BrandMarkView(size: 46, level: level, isListening: isListening)

            VStack(alignment: .leading, spacing: 2) {
                Text("Voice Router")
                    .font(.system(size: titleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(VoiceRouterTheme.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VoiceRouterTheme.textMuted)
                }
            }
        }
    }
}

struct IslandPreviewCard: View {
    let title: String
    let subtitle: String
    let level: CGFloat
    let isListening: Bool

    var body: some View {
        HStack(spacing: 16) {
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.80))
                .frame(width: 166, height: 58)
                .overlay(
                    HStack(spacing: 12) {
                        Circle()
                            .fill(isListening ? VoiceRouterTheme.softCoral : VoiceRouterTheme.warmAmber.opacity(0.92))
                            .frame(width: 10, height: 10)

                        VoiceWaveView(level: isListening ? max(level, 0.20) : 0.12, barWidth: 4, maxHeight: 20, idleHeight: 7)

                        Text(isListening ? "Listening" : "Ready")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(VoiceRouterTheme.textPrimary.opacity(0.92))
                    }
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(0.9)
                    .foregroundStyle(VoiceRouterTheme.textMuted)

                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(VoiceRouterTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .voiceRouterPanel(radius: 26, tint: isListening ? VoiceRouterTheme.coolCyan : VoiceRouterTheme.warmAmber)
    }
}

private struct VoiceRouterPanelModifier: ViewModifier {
    let radius: CGFloat
    let tint: Color

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                VoiceRouterTheme.cardFillTop,
                                tint.opacity(0.05),
                                VoiceRouterTheme.cardFillBottom
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(VoiceRouterTheme.cardStroke, lineWidth: 1)
                    )
                    .shadow(color: tint.opacity(0.08), radius: 28, y: 16)
            )
    }
}

extension View {
    func voiceRouterPanel(radius: CGFloat = 28, tint: Color = VoiceRouterTheme.coolCyan) -> some View {
        modifier(VoiceRouterPanelModifier(radius: radius, tint: tint))
    }
}
