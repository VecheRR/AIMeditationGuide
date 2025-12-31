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
        .alert(String(localized: "player_finish_title"), isPresented: $showFinishConfirmation) {
            Button(String(localized: "player_finish_btn_finish"), role: .destructive) {
                audio.stop()
                dismiss()
                onFinishEarly?()
            }
            Button(String(localized: "player_finish_btn_cancel"), role: .cancel) {
                showFinishConfirmation = false
            }
        } message: {
            Text(String(localized: "player_finish_message"))
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.primary)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text(String(localized: "player_a11y_close")))

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
            .accessibilityLabel(Text(String(localized: "player_a11y_favorites")))
        }
    }

    private var header: some View {
        let subtitle = String(
            format: NSLocalizedString("player_cover_subtitle_minutes", comment: "e.g. 10 min session"),
            durationMinutes
        )

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

                Text(summary.isEmpty ? String(localized: "player_summary_fallback") : summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

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
            .accessibilityLabel(Text(String(localized: "player_a11y_voice_options")))

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
            .accessibilityLabel(Text(audio.isPlaying ? String(localized: "player_a11y_pause") : String(localized: "player_a11y_play")))
            .accessibilityHint(Text(String(localized: "player_a11y_play_hint")))

            Button {
                // потом: timer
            } label: {
                Image(systemName: "timer")
                    .foregroundStyle(.primary)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text(String(localized: "player_a11y_timer_options")))
        }
    }

    private var timeline: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { audio.currentTime },
                    set: { audio.seek(to: $0) }
                ),
                in: 0...audio.duration
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

    private var bottomBar: some View {
        let bgName = background.rawValue.lowercased()
        let bgA11y = String(format: NSLocalizedString("player_a11y_background_fmt", comment: "Background sound: %s"), bgName)

        return HStack {
            Button { showBgPicker = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "music.note")
                    Text(bgName)
                        .textCase(.lowercase)
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
                    Text(String(localized: "player_btn_finish_early"))
                }
                .font(.caption.bold())
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .accessibilityLabel(Text(String(localized: "player_a11y_finish_early")))

            Spacer()

            if let onSave {
                Button {
                    guard !isAlreadySaved && !didSaveFromPlayer else { return }
                    onSave()
                    didSaveFromPlayer = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: (didSaveFromPlayer || isAlreadySaved) ? "checkmark" : "tray.and.arrow.down")
                        Text((didSaveFromPlayer || isAlreadySaved) ? String(localized: "player_btn_saved") : String(localized: "player_btn_save_history"))
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .accessibilityLabel(Text(String(localized: "player_a11y_save_history")))
                .disabled(isAlreadySaved || didSaveFromPlayer)
            }
        }
        .padding(.top, 12)
    }

    private func volumeSlider(titleKey: String, value: Binding<Double>) -> some View {
        HStack(spacing: 10) {
            Text(String(localized: String.LocalizationValue(titleKey)))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)

            Slider(value: value, in: 0...1)
                .tint(.accentColor)
                .accessibilityLabel(Text(String(format: NSLocalizedString("player_a11y_volume_fmt", comment: "%s volume"), NSLocalizedString(titleKey, comment: ""))))
        }
    }

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
