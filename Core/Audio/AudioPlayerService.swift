//
//  AudioPlayerService.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioPlayerService: ObservableObject {
    private var voicePlayer: AVAudioPlayer?
    private var bgPlayer: AVAudioPlayer?
    private var timer: Timer?

    private var targetDuration: TimeInterval = 0

    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0

    /// Общая длительность сессии (то, что выбрал пользователь)
    @Published var duration: TimeInterval = 1

    @Published var voiceVolume: Float = 1.0 {
        didSet { voicePlayer?.volume = voiceVolume }
    }

    @Published var bgVolume: Float = 0.35 {
        didSet { bgPlayer?.volume = bgVolume }
    }

    /// targetSeconds — сколько минут выбрал пользователь * 60
    func load(
        voiceURL: URL?,
        background: GenBackground,
        backgroundURL: URL? = nil,
        targetSeconds: TimeInterval
    ) throws {
        stop()

        targetDuration = max(targetSeconds, 1)
        duration = targetDuration
        currentTime = 0

        if let voiceURL {
            voicePlayer = try AVAudioPlayer(contentsOf: voiceURL)
            voicePlayer?.prepareToPlay()
            voicePlayer?.volume = voiceVolume
        }

        if background != .none, let url = backgroundURL ?? SoundLibrary.url(for: background) {
            bgPlayer = try AVAudioPlayer(contentsOf: url)
            bgPlayer?.numberOfLoops = -1
            bgPlayer?.prepareToPlay()
            bgPlayer?.volume = bgVolume
        }
    }

    func play() {
        voicePlayer?.play()
        bgPlayer?.play()
        isPlaying = true
        startTimer()
    }

    func pause() {
        voicePlayer?.pause()
        bgPlayer?.pause()
        isPlaying = false
        stopTimer()
    }

    func stop() {
        pause()
        voicePlayer = nil
        bgPlayer = nil
        targetDuration = 0
        currentTime = 0
        duration = 1
    }

    func seek(to time: TimeInterval) {
        let clamped = min(max(time, 0), duration)
        currentTime = clamped

        // Двигаем голос, если он есть
        if let vp = voicePlayer {
            let voiceDur = max(vp.duration, 0)
            vp.currentTime = min(clamped, voiceDur)
        }
    }

    private func startTimer() {
        stopTimer()

        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self else { return }

            Task { @MainActor in
                guard self.isPlaying else { return }

                // 1) Базово считаем время по "сессии"
                var next = self.currentTime + 0.2

                // 2) Если голос ещё играет — синхронизируем currentTime с голосом (точнее)
                if let vp = self.voicePlayer, vp.isPlaying {
                    next = vp.currentTime
                }

                // 3) Обновляем общий таймер
                self.currentTime = min(next, self.duration)

                // 4) Если дошли до конца — останавливаем всё
                if self.currentTime >= self.duration {
                    self.pause()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

enum SoundLibrary {
    static func url(for bg: GenBackground) -> URL? {
        // waves.mp3 / birds.mp3 / river.mp3
        switch bg {
        case .nature:
            return Bundle.main.url(forResource: "birds", withExtension: "mp3")
        case .ambient:
            return Bundle.main.url(forResource: "waves", withExtension: "mp3")
        case .rain:
            return Bundle.main.url(forResource: "river", withExtension: "mp3")
        case .none:
            return nil
        }
    }
}
