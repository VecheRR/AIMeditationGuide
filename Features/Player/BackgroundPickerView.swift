//
//  BackgroundPickerView.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI

struct BackgroundPickerView: View {
    @Binding var selected: GenBackground
    @Binding var volume: Float
    
    @Environment(\.dismiss) private var dismiss

    private let grid = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BACKGROUND SOUNDS")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.top, 10)

            LazyVGrid(columns: grid, spacing: 12) {
                tile(.none, icon: "speaker.slash.fill")
                tile(.nature, icon: "leaf.fill")
                tile(.ambient, icon: "music.note")
                tile(.rain, icon: "cloud.rain.fill")
            }

            Text("Background Volume")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 6)

            Slider(value: $volume, in: 0...1)
            Spacer()
        }
        .padding(16)
        .background(AppBackground().ignoresSafeArea())
    }

    private func tile(_ bg: GenBackground, icon: String) -> some View {
        Button {
            selected = bg
            dismiss()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                Text(bg.rawValue)
                    .font(.caption.bold())
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, minHeight: 110)
            .background(Color.white.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                if selected == bg {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.6), lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
