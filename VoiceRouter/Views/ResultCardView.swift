import SwiftUI

struct ResultCardView: View {
    let capture: Capture
    let onDismiss: () -> Void
    let onRetry: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                HStack(spacing: 12) {
                    BrandMarkView(size: 48, level: 0.20, isListening: false)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Clipboard Ready")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(VoiceRouterTheme.textPrimary)
                        outputBadge
                    }
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(VoiceRouterTheme.textMuted.opacity(0.86))
                }
            }

            section(title: "Clipboard Text", tint: capture.outputStyle.color) {
                Text(capture.clipboardText)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(VoiceRouterTheme.textPrimary)
                    .lineLimit(9)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if capture.rawTranscript != capture.clipboardText {
                section(title: "Heard", tint: VoiceRouterTheme.warmAmber) {
                    Text(capture.rawTranscript)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(VoiceRouterTheme.textSecondary)
                        .lineLimit(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if let note = capture.note {
                Label(note, systemImage: "sparkles")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(capture.outputStyle.color)
            }

            if capture.status == .failed, let errorMessage = capture.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(VoiceRouterTheme.warning)
            }

            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: capture.status == .saved ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(capture.status == .saved ? "Copied to clipboard" : "Copy failed")
                        .font(.caption)
                }
                .foregroundStyle(capture.status == .saved ? VoiceRouterTheme.success : VoiceRouterTheme.warning)

                Spacer()

                if capture.status == .failed {
                    Button(action: onRetry) {
                        Label("Retry Copy", systemImage: "arrow.clockwise")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(VoiceRouterTheme.coolCyan)
                }

                Button(action: onDismiss) {
                    Label("New Capture", systemImage: "plus.circle.fill")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(VoiceRouterTheme.coolCyan)
            }
        }
        .padding(22)
        .voiceRouterPanel(radius: 28, tint: capture.outputStyle.color)
        .scaleEffect(appeared ? 1.0 : 0.9)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }

    private var outputBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: capture.outputStyle.icon)
                .font(.caption)
            Text(capture.outputStyle.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(capture.outputStyle.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(capture.outputStyle.color.opacity(0.15))
        )
    }

    private func section<Content: View>(title: String, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(0.9)
                .foregroundStyle(VoiceRouterTheme.textMuted)

            content()
                .padding(16)
                .voiceRouterPanel(radius: 20, tint: tint)
        }
    }
}
