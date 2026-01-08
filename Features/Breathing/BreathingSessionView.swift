import SwiftUI
import SwiftData

struct BreathingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @ObservedObject var vm: BreathingViewModel

    @State private var countdown = 3
    @State private var isCountingDown = true
    @State private var muteHints = false
    @State private var didSave = false
    @State private var showCompletion = false

    @State private var countdownTimer: Timer?

    // Language (важно!)
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.system.rawValue
    private var lang: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .system }

    var body: some View {
        ZStack {
            AppBackground()
                .overlay(Color.white.opacity(0.08).ignoresSafeArea())

            VStack {
                topBar
                Spacer()
                breathingCircle
                Spacer()
                bottomBar
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .onAppear { startCountdown() }
        .onDisappear {
            countdownTimer?.invalidate()
            countdownTimer = nil
            vm.stop()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)

        .onChange(of: vm.isFinished) { _, finished in
            guard finished else { return }

            Analytics.event("session_complete", [
                "type": "breathing",
                "duration_sec": vm.duration?.seconds ?? 0,
                "mood": vm.mood?.rawValue ?? "unknown"
            ])

            saveBreathingLogIfNeeded()
            showCompletion = true
        }

        .alert(L10n.s("bre_complete_title", lang: lang), isPresented: $showCompletion) {
            Button(L10n.s("common_close", lang: lang)) { dismiss() }
            Button(L10n.s("common_restart", lang: lang)) { restart() }
        } message: {
            Text(L10n.s("bre_complete_saved", lang: lang))
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.black)
                    .padding(10)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text(L10n.s("bre_a11y_close", lang: lang)))

            Spacer()
        }
        .padding(.top, 4)
    }

    private var breathingCircle: some View {
        let label: String = isCountingDown
            ? "\(countdown)"
            : L10n.s(vm.phase.titleKey, lang: lang)

        let p = isCountingDown ? 0.0 : vm.phaseProgress

        let innerScale: CGFloat
        let outerScale: CGFloat

        if isCountingDown {
            innerScale = 0.9
            outerScale = 0.65
        } else {
            switch vm.phase {
            case .inhale:
                innerScale = CGFloat(0.85 + 0.35 * p)
                outerScale = CGFloat(0.95 + 0.20 * p)
            case .hold:
                innerScale = 1.20
                outerScale = 1.15
            case .exhale:
                innerScale = CGFloat(1.20 - 0.35 * p)
                outerScale = CGFloat(1.15 - 0.20 * p)
            }
        }

        let anim = Animation.linear(duration: Double(max(vm.phaseDuration, 1)))

        return ZStack {
            Circle()
                .fill(Color.blue.opacity(0.10))
                .frame(width: 260, height: 260)
                .scaleEffect(outerScale)
                .animation(isCountingDown ? .easeInOut(duration: 0.3) : anim, value: outerScale)

            Circle()
                .fill(Color.blue.opacity(0.25))
                .frame(width: 140, height: 140)
                .scaleEffect(innerScale)
                .animation(isCountingDown ? .easeInOut(duration: 0.3) : anim, value: innerScale)

            Text(label)
                .font(.system(size: isCountingDown ? 34 : 22, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.18))
                .clipShape(Capsule())
                .animation(.easeInOut(duration: 0.2), value: countdown)
                .glassEffect(in: .capsule)
        }
    }

    private var bottomBar: some View {
        HStack {
            Button { muteHints.toggle() } label: {
                Image(systemName: muteHints ? "speaker.slash" : "speaker.wave.2")
                    .foregroundColor(.black)
                    .padding(10)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Circle())
                    .glassEffect()
            }
            .accessibilityLabel(
                Text(
                    muteHints
                    ? L10n.s("bre_a11y_unmute_hints", lang: lang)
                    : L10n.s("bre_a11y_mute_hints", lang: lang)
                )
            )

            Spacer()

            VStack(spacing: 4) {
                Text(timeString(vm.totalRemaining))
                    .font(.caption.bold())
                    .foregroundColor(.black.opacity(0.7))

                Text(L10n.s("bre_remaining", lang: lang))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if !muteHints {
                    Text(L10n.s(vm.phase.instructionKey, lang: lang))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.black)
                        .padding(.top, 2)
                }
            }

            Spacer()

            Button { restart() } label: {
                Image(systemName: "gobackward")
                    .foregroundColor(.black)
                    .padding(10)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text(L10n.s("bre_a11y_restart", lang: lang)))
        }
        .padding(.bottom, 6)
    }

    private func startCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil

        isCountingDown = true
        countdown = 3
        didSave = false
        showCompletion = false

        vm.prepareForStart()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if countdown <= 1 {
                t.invalidate()
                countdownTimer = nil
                isCountingDown = false
                vm.start()
            } else {
                countdown -= 1
            }
        }
    }

    private func restart() {
        vm.reset()
        startCountdown()
    }

    private func timeString(_ seconds: Int) -> String {
        let s = max(seconds, 0)
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }

    private func saveBreathingLogIfNeeded() {
        guard !didSave,
              let duration = vm.duration,
              let mood = vm.mood
        else { return }

        let log = BreathingLog(durationSeconds: duration.seconds, mood: mood)
        modelContext.insert(log)
        didSave = true
    }
}
