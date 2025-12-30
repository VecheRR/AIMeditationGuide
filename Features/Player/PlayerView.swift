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

    @StateObject private var audio = AudioPlayerService()
    @State private var showBgPicker = false

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
                    volumeSlider(title: "Voice", value: Binding(
                        get: { Double(audio.voiceVolume) },
                        set: { audio.voiceVolume = Float($0) }
                    ))

                    volumeSlider(title: "Background", value: Binding(
                        get: { Double(audio.bgVolume) },
                        set: { audio.bgVolume = Float($0) }
                    ))
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
        .sheet(isPresented: $showBgPicker) {
            BackgroundPickerView(selected: $background, volume: $audio.bgVolume)
                .presentationDetents([.medium])
        }
        .onChange(of: background) { _, newValue in
            let wasPlaying = audio.isPlaying
            let target = TimeInterval(durationMinutes * 60)

            // перезагрузить фон, но НЕ терять голос
            try? audio.load(
                voiceURL: voiceURL,
                background: newValue,
                backgroundURL: resolvedBackgroundURL(for: newValue),
                targetSeconds: target
            )

            if wasPlaying { audio.play() }
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
            .accessibilityLabel("Close player")
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
            .accessibilityLabel("Save to favorites")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            KenBurnsCoverView(
                imageURL: coverURL,
                title: title,
                subtitle: "\(durationMinutes) min session"
            )
            .frame(height: 210)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text(summary.isEmpty ? "Relax and follow the guidance." : summary)
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
            .accessibilityLabel("Voice options")

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
            .accessibilityLabel(audio.isPlaying ? "Pause" : "Play")
            .accessibilityHint("Controls both voice and background")

            Button {
                // потом: timer
            } label: {
                Image(systemName: "timer")
                    .foregroundStyle(.primary)
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Timer options")
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
        HStack {
            Button {
                showBgPicker = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "music.note")
                    Text(background.rawValue)
                        .textCase(.lowercase)
                }
                .font(.caption.bold())
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .accessibilityLabel("Background sound: \(background.rawValue)")

            Spacer()

            Button {
                // потом: share
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(.primary)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Share session")
        }
        .padding(.top, 12)
    }

    private func volumeSlider(title: String, value: Binding<Double>) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)

            Slider(value: value, in: 0...1)
                .tint(.accentColor)
                .accessibilityLabel(Text("\(title) volume"))
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
