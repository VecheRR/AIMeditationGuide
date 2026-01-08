import Foundation
import SwiftUI
import Combine

@MainActor
final class BreathingViewModel: ObservableObject {

    @Published var mood: BreathingMood? = nil
    @Published var duration: BreathingDuration? = nil

    @Published var phase: BreathingPhase = .inhale
    @Published var phaseRemaining: Int = 0
    @Published var totalRemaining: Int = 0
    @Published var isRunning = false
    @Published var isFinished = false

    @Published var phaseDuration: Int = 1
    @Published var phaseProgress: Double = 0

    private var pattern: BreathingPattern?
    private var timer: Timer?

    private var initialTotal: Int { duration?.seconds ?? 0 }
    var canStart: Bool { mood != nil && duration != nil }

    // ✅ было String → стало LocalizedStringKey
//    var instructionKey: LocalizedStringKey { phase.instructionKey }

    func prepareForStart() {
        totalRemaining = initialTotal
    }

    func start() {
        guard let mood, let duration else { return }

        pattern = BreathingPattern.forMood(mood)
        totalRemaining = duration.seconds

        setPhase(.inhale)
        isRunning = true
        isFinished = false
        startTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func reset() {
        stop()
        phase = .inhale
        phaseRemaining = 0
        totalRemaining = 0
        phaseDuration = 1
        phaseProgress = 0
        isFinished = false
    }

    private func startTimer() {
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard self.isRunning else { return }

                self.totalRemaining -= 1
                self.phaseRemaining -= 1

                self.recalcProgress()

                if self.phaseRemaining <= 0 {
                    self.advancePhase()
                }

                if self.totalRemaining <= 0 {
                    self.finish()
                }
            }
        }
    }

    private func recalcProgress() {
        let dur = max(phaseDuration, 1)
        let done = dur - max(phaseRemaining, 0)
        phaseProgress = min(max(Double(done) / Double(dur), 0), 1)
    }

    private func setPhase(_ new: BreathingPhase) {
        phase = new
        phaseDuration = durationForPhase(new)
        phaseRemaining = phaseDuration
        phaseProgress = 0
    }

    private func durationForPhase(_ p: BreathingPhase) -> Int {
        guard let pattern else { return 1 }
        switch p {
        case .inhale: return pattern.inhale
        case .hold:   return pattern.hold
        case .exhale: return pattern.exhale
        }
    }

    private func advancePhase() {
        switch phase {
        case .inhale: setPhase(.hold)
        case .hold:   setPhase(.exhale)
        case .exhale: setPhase(.inhale)
        }
    }

    private func finish() {
        stop()
        phaseRemaining = 0
        totalRemaining = 0
        isFinished = true
    }
}
