import SwiftUI

struct CaptureView: View {
    @EnvironmentObject private var captureStore: CaptureStore
    @EnvironmentObject private var speechService: SpeechService
    @EnvironmentObject private var settings: AppSettingsStore

    var body: some View {
        CaptureViewInner(speechService: speechService)
            .environmentObject(captureStore)
            .environmentObject(settings)
    }
}

private struct CaptureViewInner: View {
    @EnvironmentObject private var captureStore: CaptureStore
    @EnvironmentObject private var settings: AppSettingsStore
    @StateObject private var viewModel: CaptureViewModel
    @State private var activeSheet: ActiveSheet?
    @State private var pulseScale: CGFloat = 1.0

    private enum ActiveSheet: Int, Identifiable {
        case history
        case settings

        var id: Int { rawValue }
    }

    init(speechService: SpeechService) {
        _viewModel = StateObject(wrappedValue: CaptureViewModel(speechService: speechService))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        heroCopy
                        transcriptPanel
                        controlPanel

                        if case .result = viewModel.state, let capture = viewModel.lastCapture {
                            ResultCardView(capture: capture) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                    viewModel.reset()
                                }
                            } onRetry: {
                                viewModel.retryCopy(capture: capture, store: captureStore)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                    .padding(.top, 12)
                }
            }
            .safeAreaInset(edge: .top) {
                statusPill
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 20)
            }
            .overlay(alignment: .bottom) {
                if viewModel.showFeedbackBanner, let feedbackMessage = viewModel.feedbackMessage {
                    Text(feedbackMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(VoiceRouterTheme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.88))
                                .overlay(
                                    Capsule()
                                        .stroke(VoiceRouterTheme.cardStroke, lineWidth: 1)
                                )
                        )
                        .padding(.bottom, 18)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        activeSheet = .history
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(VoiceRouterTheme.textPrimary)
                            .frame(width: 38, height: 38)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                }

                ToolbarItem(placement: .principal) {
                    BrandLockupView(
                        level: viewModel.speechService.audioLevel,
                        isListening: viewModel.isListening,
                        titleSize: 16,
                        subtitle: nil
                    )
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .settings
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(VoiceRouterTheme.textPrimary)
                            .frame(width: 38, height: 38)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .history:
                    HistoryView()
                case .settings:
                    SettingsView()
                }
            }
        }
        .task {
            await viewModel.prepare()
        }
        .onChange(of: viewModel.speechService.transcript) { _ in
            viewModel.handleTranscriptChanged(store: captureStore, settings: settings)
        }
        .onReceive(NotificationCenter.default.publisher(for: .startCapture)) { notification in
            let source = notification.object as? CaptureLaunchSource ?? .manual
            Task {
                await viewModel.startCapture(source: source)
            }
        }
    }

    private var background: some View {
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

            Circle()
                .fill(VoiceRouterTheme.coolCyan.opacity(0.20))
                .frame(width: 320, height: 320)
                .blur(radius: 40)
                .offset(x: 110, y: -260)

            Circle()
                .fill(VoiceRouterTheme.softCoral.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 54)
                .offset(x: -140, y: 240)

            Circle()
                .fill(VoiceRouterTheme.warmAmber.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 46)
                .offset(x: 130, y: 180)
        }
    }

    private var heroCopy: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    heroCopyText

                    Spacer(minLength: 0)

                    BrandMarkView(
                        size: 112,
                        level: viewModel.speechService.audioLevel,
                        isListening: viewModel.isListening
                    )
                }

                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Spacer(minLength: 0)
                        BrandMarkView(
                            size: 104,
                            level: viewModel.speechService.audioLevel,
                            isListening: viewModel.isListening
                        )
                    }

                    heroCopyText
                }
            }

            IslandPreviewCard(
                title: "Action Button Cue",
                subtitle: viewModel.isListening
                    ? "The top capsule is active now, so capture feels immediate before you even check the transcript."
                    : "Press once and the island-style cue wakes up first, so the app looks alive before you start talking.",
                level: viewModel.speechService.audioLevel,
                isListening: viewModel.isListening
            )
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .voiceRouterPanel(
            radius: 32,
            tint: viewModel.isListening ? VoiceRouterTheme.softCoral : VoiceRouterTheme.coolCyan
        )
    }

    private var heroCopyText: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Speak.\nPaste.\nMove on.")
                .font(.system(size: 39, weight: .heavy, design: .rounded))
                .foregroundStyle(VoiceRouterTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Voice Router is built for the quick-capture flow: instant feedback, clean transcription, and clipboard-ready text without ceremony.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(VoiceRouterTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    featureChip(
                        title: settings.useAppleIntelligenceFormatting ? "Formatting On" : "Raw Transcript",
                        icon: settings.useAppleIntelligenceFormatting ? "sparkles" : "waveform"
                    )
                    featureChip(
                        title: settings.automaticallyFinishAfterPause ? "Pause to Finish" : "Manual Stop",
                        icon: settings.automaticallyFinishAfterPause ? "pause.circle" : "hand.tap"
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    featureChip(
                        title: settings.useAppleIntelligenceFormatting ? "Formatting On" : "Raw Transcript",
                        icon: settings.useAppleIntelligenceFormatting ? "sparkles" : "waveform"
                    )
                    featureChip(
                        title: settings.automaticallyFinishAfterPause ? "Pause to Finish" : "Manual Stop",
                        icon: settings.automaticallyFinishAfterPause ? "pause.circle" : "hand.tap"
                    )
                }
            }
        }
    }

    private var transcriptPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(panelEyebrow)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(VoiceRouterTheme.textMuted)
                    .tracking(1.1)

                Spacer()

                if viewModel.isListening {
                    Label("Live", systemImage: "dot.radiowaves.left.and.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(VoiceRouterTheme.coolCyan)
                } else if settings.useAppleIntelligenceFormatting {
                    Label("Polish Enabled", systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(VoiceRouterTheme.warmAmber)
                }
            }

            Text(displayTranscript)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    displayTranscriptIsPlaceholder
                        ? VoiceRouterTheme.textMuted.opacity(0.86)
                        : VoiceRouterTheme.textPrimary
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.easeOut(duration: 0.16), value: viewModel.speechService.transcript)

            if let supportingMessage {
                Text(supportingMessage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(VoiceRouterTheme.textSecondary.opacity(0.88))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
        .voiceRouterPanel(
            radius: 30,
            tint: viewModel.isListening ? VoiceRouterTheme.coolCyan : VoiceRouterTheme.warmAmber
        )
    }

    private var controlPanel: some View {
        VStack(spacing: 18) {
            Text("CAPTURE CONTROL")
                .font(.caption.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(VoiceRouterTheme.textMuted)

            Button {
                if viewModel.isListening {
                    Task {
                        await viewModel.stopCapture(store: captureStore, settings: settings)
                    }
                } else {
                    Task {
                        await viewModel.startCapture(source: .manual)
                    }
                }
            } label: {
                ZStack {
                    if viewModel.isListening {
                        Circle()
                            .stroke(VoiceRouterTheme.softCoral.opacity(0.24), lineWidth: 2.5)
                            .frame(width: 148, height: 148)
                            .scaleEffect(pulseScale)
                            .opacity(2.0 - Double(pulseScale))
                            .onAppear {
                                withAnimation(.easeOut(duration: 1.1).repeatForever(autoreverses: false)) {
                                    pulseScale = 1.75
                                }
                            }
                            .onDisappear {
                                pulseScale = 1.0
                            }
                    }

                    Circle()
                        .fill(
                            viewModel.isListening
                                ? LinearGradient(
                                    colors: [
                                        VoiceRouterTheme.softCoral,
                                        VoiceRouterTheme.warmAmber.opacity(0.86)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [
                                        VoiceRouterTheme.coolCyan,
                                        VoiceRouterTheme.freshMint
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .frame(width: 118, height: 118)
                        .shadow(
                            color: (viewModel.isListening
                                ? VoiceRouterTheme.softCoral
                                : VoiceRouterTheme.coolCyan)
                                .opacity(0.34),
                            radius: 26,
                            y: 12
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )

                    Image(systemName: viewModel.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: viewModel.isListening ? 30 : 38, weight: .bold))
                        .foregroundStyle(VoiceRouterTheme.textPrimary)
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isProcessing)

            Text(controlLabel)
                .font(.headline.weight(.semibold))
                .foregroundStyle(VoiceRouterTheme.textPrimary)

            Text(controlHint)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(VoiceRouterTheme.textSecondary.opacity(0.88))
                .padding(.horizontal, 10)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
        .voiceRouterPanel(
            radius: 32,
            tint: viewModel.isListening ? VoiceRouterTheme.softCoral : VoiceRouterTheme.coolCyan
        )
    }

    private var statusPill: some View {
        HStack(spacing: 12) {
            pillIndicator

            VStack(alignment: .leading, spacing: 2) {
                Text(pillTitle)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(VoiceRouterTheme.textPrimary)
                Text(pillSubtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(VoiceRouterTheme.textSecondary.opacity(0.86))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.76))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(VoiceRouterTheme.cardStroke, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: viewModel.state)
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: viewModel.speechService.audioLevel)
    }

    @ViewBuilder
    private var pillIndicator: some View {
        switch viewModel.state {
        case .idle:
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(VoiceRouterTheme.coolCyan)
        case .listening:
            VoiceWaveView(
                level: viewModel.speechService.audioLevel,
                barWidth: 4,
                maxHeight: 24,
                idleHeight: 8
            )
            .frame(width: 30, height: 26, alignment: .center)
        case .processing:
            ProgressView()
                .progressViewStyle(.circular)
                .tint(VoiceRouterTheme.warmAmber)
                .frame(width: 26, height: 26)
        case .result:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(VoiceRouterTheme.success)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundStyle(VoiceRouterTheme.warning)
        }
    }

    private func featureChip(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(VoiceRouterTheme.textPrimary.opacity(0.92))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.07))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var displayTranscript: String {
        if !viewModel.speechService.transcript.isEmpty {
            return viewModel.speechService.transcript
        }

        if let capture = viewModel.lastCapture, case .result = viewModel.state {
            return capture.rawTranscript
        }

        if case .error(let message) = viewModel.state {
            return message
        }

        return "Your live transcript shows up here. If Action Button launches the app, the top capsule will pulse first so you know it’s listening."
    }

    private var displayTranscriptIsPlaceholder: Bool {
        if case .error = viewModel.state {
            return false
        }

        viewModel.speechService.transcript.isEmpty && !(viewModel.lastCapture != nil && isShowingResult)
    }

    private var panelEyebrow: String {
        switch viewModel.state {
        case .idle:
            return "READY"
        case .listening:
            return "LIVE TRANSCRIPT"
        case .processing:
            return "FINALIZING"
        case .result:
            return "WHAT YOU SAID"
        case .error:
            return "ATTENTION"
        }
    }

    private var supportingMessage: String? {
        switch viewModel.state {
        case .idle:
            return settings.automaticallyFinishAfterPause
                ? "Capture ends automatically after a short pause, then the text is copied."
                : "Tap the button again when you want to stop listening."
        case .listening:
            return settings.automaticallyFinishAfterPause
                ? "Pause for a beat when you’re done, or tap the button to finish right away."
                : "Tap the button again when you’re finished speaking."
        case .processing(let message):
            return message
        case .result:
            return "The clipboard-ready output is below."
        case .error:
            return "Open Settings if permissions are off, then try again."
        }
    }

    private var controlLabel: String {
        switch viewModel.state {
        case .idle:
            return "Start a capture"
        case .listening:
            return "Listening now"
        case .processing:
            return "Working on it"
        case .result:
            return "Ready for another one"
        case .error:
            return "Try again"
        }
    }

    private var controlHint: String {
        switch viewModel.state {
        case .idle:
            return "One tap to listen, transcribe, and copy."
        case .listening:
            return settings.automaticallyFinishAfterPause
                ? "Keep talking. A short pause will finish the capture automatically."
                : "Tap the button again to stop and copy."
        case .processing:
            return "The app is preparing the final clipboard text."
        case .result:
            return "The last result is already on your clipboard."
        case .error:
            return "Voice Router could not start capture."
        }
    }

    private var pillTitle: String {
        switch viewModel.state {
        case .idle:
            return "Ready"
        case .listening(let source):
            return source == .shortcut ? "Action Button Capture" : "Listening"
        case .processing:
            return "Finalizing"
        case .result:
            return "Copied"
        case .error:
            return "Needs Attention"
        }
    }

    private var pillSubtitle: String {
        switch viewModel.state {
        case .idle:
            return settings.useAppleIntelligenceFormatting
                ? "Will polish with Apple Intelligence when available."
                : "Will copy the raw transcript."
        case .listening:
            return "Speak now. The live transcript updates as you talk."
        case .processing(let message):
            return message
        case .result:
            return viewModel.lastCapture?.outputStyle.displayName ?? "Clipboard updated."
        case .error(let message):
            return message
        }
    }

    private var isShowingResult: Bool {
        if case .result = viewModel.state {
            return true
        }
        return false
    }

}
