//
//  BreathingSessionView.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 29.12.2025.
//

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
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            countdownTimer?.invalidate()
            countdownTimer = nil
            vm.stop()
        }
        // убираем системную навигацию (и Back тоже)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)

        // iOS 17-safe вариант
        .onChange(of: vm.isFinished) { _, finished in
            guard finished else { return }
            saveBreathingLogIfNeeded()
            showCompletion = true
        }

        .alert("Breathing complete", isPresented: $showCompletion) {
            Button("Close") { dismiss() }
            Button("Restart") { restart() }
        } message: {
            Text("Session saved to history")
        }
    }

    // MARK: - Top Bar (только одна кнопка закрыть)

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.black)
                    .padding(10)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Circle())
            }

            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - Center

    private var breathingCircle: some View {
        let label = isCountingDown ? "\(countdown)" : vm.phase.rawValue
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
                .animation(.easeInOut(duration: 0.2), value: label)
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Button {
                muteHints.toggle()
            } label: {
                Image(systemName: muteHints ? "speaker.slash" : "speaker.wave.2")
                    .foregroundColor(.black)
                    .padding(10)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 4) {
                Text(timeString(vm.totalRemaining))
                    .font(.caption.bold())
                    .foregroundColor(.black.opacity(0.7))
                Text("Remaining")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if !muteHints {
                    Text(vm.instruction)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.black)
                        .padding(.top, 2)
                }
            }

            Spacer()

            Button {
                restart()
            } label: {
                Image(systemName: "gobackward")
                    .foregroundColor(.black)
                    .padding(10)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Circle())
            }
        }
        .padding(.bottom, 6)
    }

    // MARK: - Helpers

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
        guard !didSave, let duration = vm.duration, let mood = vm.mood else { return }
        let log = BreathingLog(durationSeconds: duration.seconds, mood: mood.rawValue)
        modelContext.insert(log)
        didSave = true
    }
}
