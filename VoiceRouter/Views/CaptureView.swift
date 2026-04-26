import SwiftUI

struct CaptureView: View {
    @EnvironmentObject private var captureStore: CaptureStore
    @EnvironmentObject private var launchCenter: CaptureLaunchCenter
    @EnvironmentObject private var speechService: SpeechService
    @EnvironmentObject private var settings: AppSettingsStore

    var body: some View {
        CaptureViewInner(speechService: speechService)
            .environmentObject(captureStore)
            .environmentObject(launchCenter)
            .environmentObject(settings)
    }
}

private struct CaptureViewInner: View {
    @EnvironmentObject private var captureStore: CaptureStore
    @EnvironmentObject private var launchCenter: CaptureLaunchCenter
    @EnvironmentObject private var settings: AppSettingsStore
    @StateObject private var viewModel: CaptureViewModel
    @State private var activeSheet: ActiveSheet?

    private enum ActiveSheet: Int, Identifiable {
        case history
        case settings

        var id: Int { rawValue }
    }

    init(speechService: SpeechService) {
        _viewModel = StateObject(wrappedValue: CaptureViewModel(speechService: speechService))
    }

    var body: some View {
        ZStack {
            background
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                customHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                statusPill
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .zIndex(1)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        summaryCard
                        transcriptPanel

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
                    .padding(.bottom, 24)
                }

                controlDock
            }
        }
        .overlay(alignment: .bottom) {
            if viewModel.showFeedbackBanner, let feedbackMessage = viewModel.feedbackMessage {
                Text(feedbackMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(VoiceRouterTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground).opacity(0.95))
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(VoiceRouterTheme.cardStroke, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 94)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
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
        .task {
            viewModel.prepare()

            if let source = launchCenter.consumePendingCapture() {
                await viewModel.startCapture(source: source)
            }
        }
        .onChange(of: viewModel.speechService.transcript) { _ in
            viewModel.handleTranscriptChanged(store: captureStore, settings: settings)
        }
        .onReceive(launchCenter.$pendingSource.compactMap { $0 }) { source in
            _ = launchCenter.consumePendingCapture()
            Task {
                await viewModel.startCapture(source: source)
            }
        }
    }

    private var customHeader: some View {
        HStack {
            Button {
                activeSheet = .history
            } label: {
                toolbarIcon(systemName: "clock.arrow.circlepath")
            }
            .buttonStyle(.plain)

            Spacer()

            BrandLockupView(
                level: viewModel.speechService.audioLevel,
                isListening: viewModel.isCaptureActive,
                titleSize: 17,
                subtitle: nil
            )

            Spacer()

            Button {
                activeSheet = .settings
            } label: {
                toolbarIcon(systemName: "slider.horizontal.3")
            }
            .buttonStyle(.plain)
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
                .fill(VoiceRouterTheme.coolCyan.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 48)
                .offset(x: 120, y: -250)

            Circle()
                .fill(VoiceRouterTheme.softCoral.opacity(0.10))
                .frame(width: 240, height: 240)
                .blur(radius: 54)
                .offset(x: -130, y: 220)
        }
    }

    private var statusPill: some View {
        HStack(spacing: 12) {
            pillIndicator

            VStack(alignment: .leading, spacing: 3) {
                Text(pillTitle)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(VoiceRouterTheme.textPrimary)

                Text(pillSubtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(VoiceRouterTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule(style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground).opacity(0.92))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(VoiceRouterTheme.cardStroke, lineWidth: 1)
                )
        )
        .shadow(color: VoiceRouterTheme.coolCyan.opacity(0.08), radius: 16, y: 8)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: viewModel.state)
    }

    @ViewBuilder
    private var pillIndicator: some View {
        switch viewModel.state {
        case .idle:
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(VoiceRouterTheme.coolCyan)
        case .arming:
            ProgressView()
                .progressViewStyle(.circular)
                .tint(VoiceRouterTheme.coolCyan)
                .frame(width: 24, height: 24)
        case .listening:
            VoiceWaveView(
                level: viewModel.speechService.audioLevel,
                barWidth: 4,
                maxHeight: 22,
                idleHeight: 8
            )
            .frame(width: 30, height: 24, alignment: .center)
        case .processing:
            ProgressView()
                .progressViewStyle(.circular)
                .tint(VoiceRouterTheme.warmAmber)
                .frame(width: 24, height: 24)
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

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                BrandMarkView(
                    size: 62,
                    level: viewModel.speechService.audioLevel,
                    isListening: viewModel.isCaptureActive
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(summaryTitle)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(VoiceRouterTheme.textPrimary)

                    Text(summarySubtitle)
                        .font(.subheadline)
                        .foregroundStyle(VoiceRouterTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Text(summaryBadgeText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(summaryBadgeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        Capsule(style: .continuous)
                            .fill(summaryBadgeColor.opacity(0.14))
                    )
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                summaryMetric(
                    title: "Launch",
                    value: "Action Button or tap",
                    icon: "button.horizontal.top.press",
                    tint: VoiceRouterTheme.coolCyan
                )
                summaryMetric(
                    title: "Finish",
                    value: settings.automaticallyFinishAfterPause ? pauseDurationLabel : "Manual stop",
                    icon: settings.automaticallyFinishAfterPause ? "timer" : "hand.tap",
                    tint: VoiceRouterTheme.freshMint
                )
                summaryMetric(
                    title: "Output",
                    value: settings.useAppleIntelligenceFormatting ? "Polished text" : "Raw transcript",
                    icon: settings.useAppleIntelligenceFormatting ? "sparkles" : "waveform",
                    tint: settings.useAppleIntelligenceFormatting ? VoiceRouterTheme.warmAmber : VoiceRouterTheme.coolCyan
                )
                summaryMetric(
                    title: "Recognition",
                    value: viewModel.speechService.supportsOnDeviceRecognition ? "On device when possible" : "Adaptive",
                    icon: "bolt.fill",
                    tint: VoiceRouterTheme.softCoral
                )
            }
        }
        .padding(20)
        .voiceRouterPanel(
            radius: 28,
            tint: viewModel.isCaptureActive ? VoiceRouterTheme.softCoral : VoiceRouterTheme.coolCyan
        )
    }

    private func summaryMetric(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                Text(title.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(VoiceRouterTheme.textMuted)
            }

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(VoiceRouterTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
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
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    displayTranscriptIsPlaceholder
                        ? VoiceRouterTheme.textMuted.opacity(0.92)
                        : VoiceRouterTheme.textPrimary
                )
                .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
                .animation(.easeOut(duration: 0.12), value: viewModel.speechService.transcript)

            if let supportingMessage {
                Text(supportingMessage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(VoiceRouterTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .voiceRouterPanel(
            radius: 28,
            tint: viewModel.isCaptureActive ? VoiceRouterTheme.coolCyan : VoiceRouterTheme.warmAmber
        )
    }

    private var controlDock: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(VoiceRouterTheme.cardStroke)

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
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(controlButtonFill)
                            .frame(width: 52, height: 52)

                        if viewModel.isProcessing || viewModel.isArming {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(VoiceRouterTheme.textPrimary)
                        } else {
                            Image(systemName: viewModel.isListening ? "stop.fill" : "mic.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(VoiceRouterTheme.textPrimary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(controlLabel)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(VoiceRouterTheme.textPrimary)

                        Text(controlHint)
                            .font(.subheadline)
                            .foregroundStyle(VoiceRouterTheme.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    if viewModel.isListening {
                        VoiceWaveView(
                            level: viewModel.speechService.audioLevel,
                            barWidth: 4,
                            maxHeight: 18,
                            idleHeight: 8
                        )
                        .frame(width: 34, height: 24)
                    } else {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title3)
                            .foregroundStyle(VoiceRouterTheme.textMuted)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground).opacity(0.92))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(VoiceRouterTheme.cardStroke, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isProcessing || viewModel.isArming)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(
                Color(uiColor: .systemBackground)
                    .opacity(0.92)
            )
        }
    }

    private func toolbarIcon(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(VoiceRouterTheme.textPrimary)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(Color(uiColor: .secondarySystemBackground).opacity(0.92))
            )
    }

    private var summaryTitle: String {
        switch viewModel.state {
        case .idle:
            return "Ready for quick capture"
        case .arming:
            return "Starting capture"
        case .listening(let source):
            return source == .shortcut ? "Capturing from Action Button" : "Listening live"
        case .processing:
            return "Finishing your text"
        case .result:
            return "Clipboard updated"
        case .error:
            return "Capture needs attention"
        }
    }

    private var summarySubtitle: String {
        switch viewModel.state {
        case .idle:
            return "One press records, a short pause can finish automatically, and the final text lands on your clipboard."
        case .arming:
            return "Voice Router is priming speech recognition so the waveform can start without the usual dead air."
        case .listening:
            return "Speak naturally. The transcript updates as you talk, and you can still tap once to finish right away."
        case .processing(let message):
            return message
        case .result:
            return "Your last capture is ready below, and the next one is one tap away."
        case .error(let message):
            return message
        }
    }

    private var summaryBadgeText: String {
        switch viewModel.state {
        case .idle:
            return "READY"
        case .arming:
            return "STARTING"
        case .listening:
            return "LIVE"
        case .processing:
            return "WORKING"
        case .result:
            return "DONE"
        case .error:
            return "CHECK"
        }
    }

    private var summaryBadgeColor: Color {
        switch viewModel.state {
        case .idle:
            return VoiceRouterTheme.coolCyan
        case .arming:
            return VoiceRouterTheme.freshMint
        case .listening:
            return VoiceRouterTheme.softCoral
        case .processing:
            return VoiceRouterTheme.warmAmber
        case .result:
            return VoiceRouterTheme.success
        case .error:
            return VoiceRouterTheme.warning
        }
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

        if case .arming = viewModel.state {
            return "Starting the microphone and speech recognizer now..."
        }

        return "Your live transcript appears here as soon as you start talking."
    }

    private var displayTranscriptIsPlaceholder: Bool {
        if case .error = viewModel.state {
            return false
        }

        return viewModel.speechService.transcript.isEmpty && !(viewModel.lastCapture != nil && isShowingResult)
    }

    private var panelEyebrow: String {
        switch viewModel.state {
        case .idle:
            return "READY"
        case .arming:
            return "STARTING"
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
                ? "Pause for about \(pauseDurationLabel.lowercased()) and Voice Router will stop automatically."
                : "Tap the control again when you want to stop listening."
        case .arming:
            return "This quick warm-up makes the interface respond immediately while speech capture comes online."
        case .listening:
            return settings.automaticallyFinishAfterPause
                ? "Keep talking. The app will finish after a short pause, or you can stop it manually."
                : "Tap the control again when you are done speaking."
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
            return "Start capture"
        case .arming:
            return "Starting capture"
        case .listening:
            return "Stop and copy"
        case .processing:
            return "Preparing clipboard text"
        case .result:
            return "Start another capture"
        case .error:
            return "Try capture again"
        }
    }

    private var controlHint: String {
        switch viewModel.state {
        case .idle:
            return "Fast path: tap here or use the Action Button shortcut."
        case .arming:
            return "Speech recognition is warming up."
        case .listening:
            return settings.automaticallyFinishAfterPause
                ? "Pause to finish automatically, or tap now to end."
                : "Tap now when you are ready to finish."
        case .processing:
            return "Voice Router is formatting the final clipboard text."
        case .result:
            return "Your last result is still on the clipboard."
        case .error:
            return "Voice Router could not start capture."
        }
    }

    private var pillTitle: String {
        switch viewModel.state {
        case .idle:
            return "Ready"
        case .arming(let source):
            return source == .shortcut ? "Launching from Action Button" : "Starting capture"
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
        case .arming:
            return "Preparing audio and transcription so the capture can begin."
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

    private var controlButtonFill: LinearGradient {
        LinearGradient(
            colors: viewModel.isListening
                ? [VoiceRouterTheme.softCoral, VoiceRouterTheme.warmAmber]
                : [VoiceRouterTheme.coolCyan, VoiceRouterTheme.freshMint],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var pauseDurationLabel: String {
        "\(settings.pauseDuration.formatted(.number.precision(.fractionLength(1))))s"
    }

    private var isShowingResult: Bool {
        if case .result = viewModel.state {
            return true
        }
        return false
    }
}
