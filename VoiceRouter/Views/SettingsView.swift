import Foundation
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettingsStore

    private let formatter = AppleIntelligenceFormatter()

    private var formatterStatus: AppleIntelligenceAvailabilityStatus {
        formatter.availabilityStatus()
    }

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
                    VStack(spacing: 16) {
                        headerCard
                        formattingCard
                        captureCard
                        actionButtonCard
                        aboutCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    BrandLockupView(titleSize: 17, subtitle: "Settings")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(VoiceRouterTheme.textPrimary)
                }
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            BrandMarkView(size: 82, level: 0.12, isListening: false)

            VStack(alignment: .leading, spacing: 8) {
                Text("Tune the quick-capture flow")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(VoiceRouterTheme.textPrimary)

                Text("These settings keep the app focused on one job: capture speech fast, prepare the right clipboard text, and stay out of the way.")
                    .font(.subheadline)
                    .foregroundStyle(VoiceRouterTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .voiceRouterPanel(radius: 28, tint: VoiceRouterTheme.coolCyan)
    }

    private var formattingCard: some View {
        settingCard(title: "Formatting", icon: "sparkles") {
            Toggle(isOn: $settings.useAppleIntelligenceFormatting) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Format with Apple Intelligence")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(VoiceRouterTheme.textPrimary)

                    Text("Clean up filler words, punctuation, and structure before copying.")
                        .font(.subheadline)
                        .foregroundStyle(VoiceRouterTheme.textSecondary)
                }
            }
            .tint(VoiceRouterTheme.warmAmber)

            Divider()
                .overlay(VoiceRouterTheme.cardStroke)

            VStack(alignment: .leading, spacing: 6) {
                Text(formatterStatus.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(formatterStatus.isReady ? VoiceRouterTheme.success : VoiceRouterTheme.warning)

                Text(formatterStatus.message)
                    .font(.subheadline)
                    .foregroundStyle(VoiceRouterTheme.textSecondary)
            }
        }
    }

    private var captureCard: some View {
        settingCard(title: "Capture Flow", icon: "waveform") {
            Toggle(isOn: $settings.automaticallyFinishAfterPause) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Automatically finish after a short pause")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(VoiceRouterTheme.textPrimary)

                    Text("Best for the one-tap Action Button flow. Turn this off if you prefer a manual stop.")
                        .font(.subheadline)
                        .foregroundStyle(VoiceRouterTheme.textSecondary)
                }
            }
            .tint(VoiceRouterTheme.coolCyan)

            Text(settings.automaticallyFinishAfterPause
                ? "Current pause window: about \(String(format: "%.1f", settings.pauseDuration)) seconds."
                : "Manual stop is active. Tap the button again to finish the capture.")
                .font(.subheadline)
                .foregroundStyle(VoiceRouterTheme.textSecondary)
        }
    }

    private var actionButtonCard: some View {
        settingCard(title: "Action Button", icon: "button.horizontal.top.press") {
            Text("Assign the `Start Capture` App Shortcut to the Action Button for the fastest flow.")
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(VoiceRouterTheme.textPrimary)

            instructionLine(number: "1", text: "Open iPhone Settings, then choose Action Button.")
            instructionLine(number: "2", text: "Pick Shortcut and select `Start Capture` from Voice Router.")
            instructionLine(number: "3", text: "Press the Action Button. Voice Router opens and starts listening immediately.")

            Text("Fallback trigger: `voicerouter://capture`")
                .font(.footnote.weight(.medium))
                .foregroundStyle(VoiceRouterTheme.textMuted)
        }
    }

    private var aboutCard: some View {
        settingCard(title: "What This App Does", icon: "doc.on.clipboard") {
            Text("Voice Router is now optimized for one job: capture speech fast, prepare clipboard-ready text, and keep a local history so nothing gets lost.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(VoiceRouterTheme.textSecondary)
        }
    }

    private func settingCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(VoiceRouterTheme.coolCyan)
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(VoiceRouterTheme.textPrimary)
            }

            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .voiceRouterPanel(radius: 24, tint: VoiceRouterTheme.coolCyan)
    }

    private func instructionLine(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(VoiceRouterTheme.canvasTop)
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(VoiceRouterTheme.warmAmber)
                )

            Text(text)
                .font(.subheadline)
                .foregroundStyle(VoiceRouterTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
