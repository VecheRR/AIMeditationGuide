//
//  PlayerView.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 29.12.2025.
//

import SwiftUI

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
            .accessibilityHint(Text(L10n.s("player_a11y_play_hint", lang: lang)))

            Button {
                // потом: timer
            } label: {
                Image(systemName: "timer")
                    .foregroundStyle(.primary)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text(L10n.s("player_a11y_timer_options", lang: lang)))
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
                Text(timeString(audio.duration))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
    }

    private func backgroundTitle(_ bg: GenBackground) -> String {
        if bg == .none {
            return L10n.s("gen_bg_none", lang: lang)
        }
        return L10n.s("gen_bg_\(bg.rawValue)", lang: lang)
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
            .accessibilityLabel(Text(L10n.s("player_a11y_finish_early", lang: lang)))

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
                .accessibilityLabel(Text(L10n.s("player_a11y_save_history", lang: lang)))
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Volume

    private func volumeSlider(titleKey: String, value: Binding<Double>) -> some View {
        let title = L10n.s(titleKey, lang: lang)
        let a11y = L10n.f("player_a11y_volume_fmt", lang: lang, title)

        return HStack(spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)

            Slider(value: value, in: 0...1)
                .tint(.accentColor)
                .accessibilityLabel(Text(a11y))
        }
    }

    // MARK: - Helpers

    private func timeString(_ t: TimeInterval) -> String {
        let total = max(Int(t.rounded()), 0)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func resolvedBackgroundURL(for background: GenBackground) -> URL? {
        if let storedBackground, storedBackground == background, let backgroundFileURL {
            return backgroundFileURL
        }
        return SoundLibrary.url(for: background)
    }
}
