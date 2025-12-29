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
    @Binding var background: GenBackground

    @StateObject private var audio = AudioPlayerService()
    @State private var showBgPicker = false

    var body: some View {
        ZStack {
            AppBackground()
                .overlay(Color.black.opacity(0.08).ignoresSafeArea())

            VStack {
                topBar

                Spacer()

                controls
                timeline

                VStack(spacing: 10) {
                    HStack {
                        Text("Voice")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                        Slider(value: Binding(
                            get: { Double(audio.voiceVolume) },
                            set: { audio.voiceVolume = Float($0) }
                        ), in: 0...1)
                        .tint(.white)
                    }

                    HStack {
                        Text("Background")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                        Slider(value: Binding(
                            get: { Double(audio.bgVolume) },
                            set: { audio.bgVolume = Float($0) }
                        ), in: 0...1)
                        .tint(.white)
                    }
                }
                .padding(.top, 8)

                bottomBar
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .onAppear {
            let target = TimeInterval(durationMinutes * 60)
            try? audio.load(voiceURL: voiceURL, background: background, targetSeconds: target)
        }
        .sheet(isPresented: $showBgPicker) {
            BackgroundPickerView(selected: $background, volume: $audio.bgVolume)
                .presentationDetents([.medium])
        }
        .onChange(of: background) { _, newValue in
            let wasPlaying = audio.isPlaying
            let target = TimeInterval(durationMinutes * 60)

            // перезагрузить фон, но НЕ терять голос
            try? audio.load(voiceURL: voiceURL, background: newValue, targetSeconds: target)

            if wasPlaying { audio.play() }
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.25))
                    .clipShape(Circle())
            }
            Spacer()
            Button {
                // потом: like/favorite
            } label: {
                Image(systemName: "heart")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.25))
                    .clipShape(Circle())
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 26) {
            Button {
                // потом: voice options
            } label: {
                Image(systemName: "waveform")
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.25))
                    .clipShape(Circle())
            }

            Button {
                audio.isPlaying ? audio.pause() : audio.play()
            } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Circle())
            }

            Button {
                // потом: timer
            } label: {
                Image(systemName: "timer")
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.25))
                    .clipShape(Circle())
            }
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
            .tint(.white)

            HStack {
                Text(timeString(audio.currentTime))
                Spacer()
                Text(timeString(audio.duration))
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.85))
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
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Spacer()

            Button {
                // потом: share
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.25))
                    .clipShape(Circle())
            }
        }
        .padding(.top, 12)
    }

    private func timeString(_ t: TimeInterval) -> String {
        let total = max(Int(t.rounded()), 0)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
