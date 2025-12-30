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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("BACKGROUND SOUNDS")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)

                    Text("Pick an ambience that lasts through the whole session.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityHint("Changes background loop without stopping the voice track")
                }

                LazyVGrid(columns: grid, spacing: 12) {
                    tile(.none, icon: "speaker.slash.fill")
                    tile(.nature, icon: "leaf.fill")
                    tile(.ambient, icon: "music.note")
                    tile(.rain, icon: "cloud.rain.fill")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Background Volume")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Slider(value: $volume, in: 0...1)
                        .tint(.accentColor)
                        .accessibilityLabel("Background volume")
                }
            }
            .padding(16)
        }
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
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, minHeight: 110)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(selected == bg ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: selected == bg ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Background \(bg.rawValue)"))
    }
}
