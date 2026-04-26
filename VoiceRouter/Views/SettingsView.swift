import AppIntents
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettingsStore

    @State private var showSiriTip = true

    private let formatter = AppleIntelligenceFormatter()

    private var formatterStatus: AppleIntelligenceAvailabilityStatus {
        formatter.availabilityStatus()
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tune the quick-capture flow")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(VoiceRouterTheme.textPrimary)

                        Text("Voice Router is meant to disappear into your day: start quickly, finish quickly, and leave you with clipboard-ready text.")
                            .font(.subheadline)
                            .foregroundStyle(VoiceRouterTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)

                Section("Capture") {
                    Toggle(isOn: $settings.automaticallyFinishAfterPause) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Automatically finish after a short pause")
                                .fontWeight(.semibold)
                            Text("Recommended for the fastest one-press workflow.")
                                .font(.subheadline)
                                .foregroundStyle(VoiceRouterTheme.textSecondary)
                        }
                    }
                    .tint(VoiceRouterTheme.coolCyan)

                    if settings.automaticallyFinishAfterPause {
                        VStack(alignment: .leading, spacing: 10) {
                            LabeledContent("Pause window") {
                                Text(pauseDurationLabel)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(VoiceRouterTheme.textPrimary)
                            }

                            Slider(value: $settings.pauseDuration, in: 0.5...1.4, step: 0.1)
                                .tint(VoiceRouterTheme.coolCyan)

                            Text("Shorter is faster. Longer is a little more forgiving before the capture stops.")
                                .font(.footnote)
                                .foregroundStyle(VoiceRouterTheme.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }

                    LabeledContent("Speech recognition") {
                        Text("On-device when supported")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(VoiceRouterTheme.textPrimary)
                    }
                }

                Section("Formatting") {
                    Toggle(isOn: $settings.useAppleIntelligenceFormatting) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Format with Apple Intelligence")
                                .fontWeight(.semibold)
                            Text("Clean up filler words, punctuation, and structure before copying.")
                                .font(.subheadline)
                                .foregroundStyle(VoiceRouterTheme.textSecondary)
                        }
                    }
                    .tint(VoiceRouterTheme.warmAmber)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(formatterStatus.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(formatterStatus.isReady ? VoiceRouterTheme.success : VoiceRouterTheme.warning)

                        Text(formatterStatus.message)
                            .font(.footnote)
                            .foregroundStyle(VoiceRouterTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }

                Section("Action Button") {
                    Text("On iPhone, go to Settings > Action Button, choose Shortcut, then select Start Voice Capture from Voice Router.")
                        .font(.subheadline)
                        .foregroundStyle(VoiceRouterTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    ShortcutsLink()

                    SiriTipView(intent: StartCaptureIntent(), isVisible: $showSiriTip)

                    Text("Fallback trigger: `voicerouter://capture`")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(VoiceRouterTheme.textMuted)
                }

                Section("About") {
                    Text("Voice Router listens, transcribes, optionally polishes the result, copies it to the clipboard, and keeps a local history so nothing gets lost.")
                        .font(.subheadline)
                        .foregroundStyle(VoiceRouterTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .scrollContentBackground(.hidden)
            .background(background)
            .navigationTitle("Settings")
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

    private var background: some View {
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
    }

    private var pauseDurationLabel: String {
        "\(settings.pauseDuration.formatted(.number.precision(.fractionLength(1)))) seconds"
    }
}
