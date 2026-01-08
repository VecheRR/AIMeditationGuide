//
//  PlayerView.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 29.12.2025.
//

import SwiftUI
import Combine

struct PlayerView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let summary: String
    let durationMinutes: Int
    let voiceURL: URL?
    let coverURL: URL?
    let storedBackground: GenBackground? = nil
    let backgroundFileURL: URL? = nil
    @Binding var background: GenBackground
    let onSave: (() -> Void)?
    let isAlreadySaved: Bool
    let onFinishEarly: (() -> Void)?

    @StateObject private var audio = AudioPlayerService()
    @State private var showBgPicker = false
    @State private var didSaveFromPlayer = false
    @State private var showFinishConfirmation = false

    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.system.rawValue
    private var lang: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .system }

    // MARK: - Sleep Timer

    private enum SleepTimerOption: String, CaseIterable, Identifiable {
        case off
        case fiveMin
        case oneMin
        case threeMin
        case endOfSession

        var id: String { rawValue }

        var title: String {
            switch self {
            case .off: return "Off"
            case .fiveMin: return "Stop in 5 min"
            case .oneMin: return "Stop in 1 min"
            case .threeMin: return "Stop in 3 min"
            case .endOfSession: return "Stop at end of session"
            }
        }

        var seconds: Int? {
            switch self {
            case .off: return nil
            case .oneMin: return 1 * 60
            case .threeMin: return 3 * 60
            case .fiveMin: return 5 * 60
            case .endOfSession: return nil
            }
        }
    }

    @State private var sleepTimer: SleepTimerOption = .off
    @State private var sleepSecondsLeft: Int? = nil
    @State private var showSleepFinishedAlert = false

    // тикер раз в секунду
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            AppBackground()
                .overlay(Color.black.opacity(0.05).ignoresSafeArea())

            VStack(spacing: 16) {
                topBar
                header

                Spacer(minLength: 8)

                controls
                timeline

                VStack(spacing: 10) {
                    volumeSlider(
                        titleKey: "player_volume_voice",
                        value: Binding(
                            get: { Double(audio.voiceVolume) },
                            set: { audio.voiceVolume = Float($0) }
                        )
                    )

                    volumeSlider(
                        titleKey: "player_volume_background",
                        value: Binding(
                            get: { Double(audio.bgVolume) },
                            set: { audio.bgVolume = Float($0) }
                        )
                    )
                }
                .padding(.top, 8)

                bottomBar
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .onAppear {
            let target = TimeInterval(durationMinutes * 60)
            try? audio.load(
                voiceURL: voiceURL,
                background: background,
                backgroundURL: resolvedBackgroundURL(for: background),
                targetSeconds: target
            )
        }
        .onDisappear { audio.stop() }

        // ✅ Sleep Timer tick
        .onReceive(tick) { _ in
            guard audio.isPlaying else { return }            // тикаем только когда играет
            guard sleepTimer != .off else { return }

            if sleepTimer == .endOfSession {
                // остановить в конце: когда дошли до конца трека (или target)
                if audio.duration > 0, audio.currentTime >= (audio.duration - 0.25) {
                    stopBySleepTimer()
                }
                return
            }

            guard let left = sleepSecondsLeft else { return }
            if left <= 1 {
                stopBySleepTimer()
            } else {
                sleepSecondsLeft = left - 1
            }
        }

        .sheet(isPresented: $showBgPicker) {
            BackgroundPickerView(selected: $background, volume: $audio.bgVolume)
                .presentationDetents([.medium])
        }
        .onChange(of: background) { _, newValue in
            let wasPlaying = audio.isPlaying
            let target = TimeInterval(durationMinutes * 60)

            try? audio.load(
                voiceURL: voiceURL,
                background: newValue,
                backgroundURL: resolvedBackgroundURL(for: newValue),
                targetSeconds: target
            )

            if wasPlaying { audio.play() }
        }

        .alert(L10n.s("player_finish_title", lang: lang), isPresented: $showFinishConfirmation) {
            Button(L10n.s("player_finish_btn_finish", lang: lang), role: .destructive) {
                audio.stop()
                dismiss()
                onFinishEarly?()
            }
            Button(L10n.s("player_finish_btn_cancel", lang: lang), role: .cancel) {
                showFinishConfirmation = false
            }
        } message: {
            Text(L10n.s("player_finish_message", lang: lang))
        }

        // ✅ Sleep timer finished
        .alert("Timer finished", isPresented: $showSleepFinishedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Playback stopped by timer.")
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.primary)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text(L10n.s("player_a11y_close", lang: lang)))

            Spacer()

            Button {
                // потом: like/favorite
            } label: {
                Image(systemName: "heart")
                    .foregroundStyle(.primary)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text(L10n.s("player_a11y_favorites", lang: lang)))
        }
    }

    // MARK: - Header

    private var header: some View {
        let subtitle = L10n.f("player_cover_subtitle_minutes", lang: lang, durationMinutes)

        return VStack(alignment: .leading, spacing: 12) {
            KenBurnsCoverView(
                imageURL: coverURL,
                title: title,
                subtitle: subtitle
            )
            .frame(height: 210)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text(summary.isEmpty ? L10n.s("player_summary_fallback", lang: lang) : summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 26) {
            Button {
                // потом: voice options
            } label: {
                Image(systemName: "waveform")
                    .foregroundStyle(.primary)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text(L10n.s("player_a11y_voice_options", lang: lang)))

            Button {
                audio.isPlaying ? audio.pause() : audio.play()
            } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                    .frame(width: 72, height: 72)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text(audio.isPlaying ? L10n.s("player_a11y_pause", lang: lang) : L10n.s("player_a11y_play", lang: lang)))

            // ✅ Sleep timer menu
            Menu {
                ForEach(SleepTimerOption.allCases) { opt in
                    Button {
                        setSleepTimer(opt)
                    } label: {
                        if opt == sleepTimer {
                            Label(opt.title, systemImage: "checkmark")
                        } else {
                            Text(opt.title)
                        }
                    }
                }

                if sleepTimer != .off {
                    Divider()
                    Button(role: .destructive) {
                        setSleepTimer(.off)
                    } label: {
                        Text("Turn off timer")
                    }
                }
            } label: {
                Image(systemName: sleepTimer == .off ? "timer" : "timer.circle.fill")
                    .foregroundStyle(.primary)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text("Sleep timer"))
        }
    }

    // MARK: - Timeline

    private var timeline: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { audio.currentTime },
                    set: { audio.seek(to: $0) }
                ),
                in: 0...max(audio.duration, 0.0001)
            )
            .tint(.accentColor)

            HStack {
                Text(timeString(audio.currentTime))

                Spacer()

                // справа: общий duration + (если включен) остаток sleep timer
                HStack(spacing: 10) {
                    if let left = sleepSecondsLeft, sleepTimer != .off, sleepTimer != .endOfSession {
                        Text("⏱ \(timeString(TimeInterval(left)))")
                    } else if sleepTimer == .endOfSession, sleepTimer != .off {
                        Text("⏱ End")
                    }

                    Text(timeString(audio.duration))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        let bgTitle = backgroundTitle(background)
        let bgA11y = L10n.f("player_a11y_background_fmt", lang: lang, bgTitle)

        return HStack {
            Button { showBgPicker = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "music.note")
                    Text(bgTitle)
                }
                .font(.caption.bold())
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .accessibilityLabel(Text(bgA11y))

            Spacer()

            Button { showFinishConfirmation = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "stop.circle")
                    Text(L10n.s("player_btn_finish_early", lang: lang))
                }
                .font(.caption.bold())
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Spacer()

            if let onSave {
                Button {
                    guard !isAlreadySaved && !didSaveFromPlayer else { return }
                    onSave()
                    didSaveFromPlayer = true
                } label: {
                    let saved = (didSaveFromPlayer || isAlreadySaved)
                    HStack(spacing: 6) {
                        Image(systemName: saved ? "checkmark" : "tray.and.arrow.down")
                        Text(saved
                             ? L10n.s("player_btn_saved", lang: lang)
                             : L10n.s("player_btn_save_history", lang: lang))
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(isAlreadySaved || didSaveFromPlayer)
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Sleep Timer helpers

    private func setSleepTimer(_ opt: SleepTimerOption) {
        sleepTimer = opt

        if opt == .off {
            sleepSecondsLeft = nil
            return
        }

        if opt == .endOfSession {
            sleepSecondsLeft = nil
            return
        }

        // фиксированное время
        sleepSecondsLeft = opt.seconds
    }

    @MainActor
    private func stopBySleepTimer() {
        audio.stop()
        sleepTimer = .off
        sleepSecondsLeft = nil
        showSleepFinishedAlert = true
    }

    // MARK: - Volume

    private func volumeSlider(titleKey: String, value: Binding<Double>) -> some View {
        let title = L10n.s(titleKey, lang: lang)
        return HStack(spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)

            Slider(value: value, in: 0...1)
                .tint(.accentColor)
        }
    }

    // MARK: - Helpers

    private func timeString(_ t: TimeInterval) -> String {
        let total = max(Int(t.rounded()), 0)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func backgroundTitle(_ bg: GenBackground) -> String {
        if bg == .none { return L10n.s("gen_bg_none", lang: lang) }
        return L10n.s("gen_bg_\(bg.rawValue)", lang: lang)
    }

    private func resolvedBackgroundURL(for background: GenBackground) -> URL? {
        if let storedBackground, storedBackground == background, let backgroundFileURL {
            return backgroundFileURL
        }
        return SoundLibrary.url(for: background)
    }
}
