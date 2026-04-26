import SwiftUI
import UIKit

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var captureStore: CaptureStore
    @State private var selectedCapture: Capture?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        VoiceRouterTheme.canvasTop,
                        VoiceRouterTheme.canvasMid,
                        VoiceRouterTheme.canvasBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if captureStore.captures.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            summaryCard

                            ForEach(captureStore.captures) { capture in
                                Button {
                                    selectedCapture = capture
                                } label: {
                                    captureCard(capture)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    BrandLockupView(titleSize: 17, subtitle: "Recent captures")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(VoiceRouterTheme.textPrimary)
                }
            }
            .sheet(item: $selectedCapture) { capture in
                CaptureDetailSheet(capture: capture)
                    .environmentObject(captureStore)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            BrandMarkView(size: 86, level: 0.12, isListening: false)

            Text("No captures yet")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(VoiceRouterTheme.textPrimary)

            Text("Every successful capture lands here, so you can always recover what was copied.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(VoiceRouterTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 26)
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 16) {
            BrandMarkView(size: 78, level: 0.14, isListening: false)

            VStack(alignment: .leading, spacing: 8) {
                Text("Saved clipboard moments")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(VoiceRouterTheme.textPrimary)

                Text("\(captureStore.captures.count) capture\(captureStore.captures.count == 1 ? "" : "s") stored locally, including fallback copies and failed attempts.")
                    .font(.subheadline)
                    .foregroundStyle(VoiceRouterTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .voiceRouterPanel(radius: 28, tint: VoiceRouterTheme.coolCyan)
    }

    private func captureCard(_ capture: Capture) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                outputBadge(for: capture)
                Spacer()
                Text(dateFormatter.string(from: capture.createdAt))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(VoiceRouterTheme.textMuted)
            }

            Text(capture.clipboardText)
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(VoiceRouterTheme.textPrimary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text("Heard")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(VoiceRouterTheme.textMuted)
                    .tracking(0.8)

                Text(capture.rawTranscript)
                    .font(.subheadline)
                    .foregroundStyle(VoiceRouterTheme.textSecondary)
                    .lineLimit(2)
            }

            if let note = capture.note {
                Label(note, systemImage: "info.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(capture.outputStyle.color)
                    .lineLimit(2)
            }

            if capture.status == .failed, let errorMessage = capture.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(VoiceRouterTheme.warning)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .voiceRouterPanel(radius: 24, tint: capture.outputStyle.color)
    }

    private func outputBadge(for capture: Capture) -> some View {
        HStack(spacing: 7) {
            Image(systemName: capture.outputStyle.icon)
            Text(capture.outputStyle.displayName)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(capture.outputStyle.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(capture.outputStyle.color.opacity(0.14))
        )
    }
}

struct CaptureDetailSheet: View {
    let capture: Capture

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var captureStore: CaptureStore
    @State private var copied = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        VoiceRouterTheme.canvasTop,
                        VoiceRouterTheme.canvasMid,
                        VoiceRouterTheme.canvasBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            HStack(spacing: 7) {
                                Image(systemName: capture.outputStyle.icon)
                                Text(capture.outputStyle.displayName)
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(capture.outputStyle.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(capture.outputStyle.color.opacity(0.14))
                            )

                            Spacer()

                            Text(dateFormatter.string(from: capture.createdAt))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(VoiceRouterTheme.textMuted)
                        }

                        section(title: "Clipboard Text") {
                            Text(capture.clipboardText)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(VoiceRouterTheme.textPrimary)
                        }

                        section(title: "Original Transcript") {
                            Text(capture.rawTranscript)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(VoiceRouterTheme.textSecondary)
                        }

                        if let note = capture.note {
                            section(title: "Notes") {
                                Text(note)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(capture.outputStyle.color)
                            }
                        }

                        if capture.status == .failed, let errorMessage = capture.errorMessage {
                            section(title: "Copy Error") {
                                Text(errorMessage)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(VoiceRouterTheme.warning)
                            }
                        }

                        HStack(spacing: 12) {
                            Button {
                                UIPasteboard.general.string = capture.clipboardText
                                copied = true
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)

                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                                    copied = false
                                }
                            } label: {
                                Label(copied ? "Copied" : "Copy Again", systemImage: copied ? "checkmark" : "doc.on.doc")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(capture.outputStyle.color)

                            Button(role: .destructive) {
                                captureStore.deleteCapture(id: capture.id)
                                dismiss()
                            } label: {
                                Label("Delete", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top, 6)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Capture Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    BrandLockupView(titleSize: 17, subtitle: "Capture detail")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(VoiceRouterTheme.textPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(VoiceRouterTheme.textMuted)
                .tracking(0.9)

            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .voiceRouterPanel(radius: 20, tint: capture.outputStyle.color)
        }
    }
}
