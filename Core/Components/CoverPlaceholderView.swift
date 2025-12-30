//
//  CoverPlaceholderView.swift
//  AIMeditationGuide
//
//  Created by OpenAI Assistant.
//

import SwiftUI

struct CoverPlaceholderView: View {
    let title: String
    let accent: Color
    let subtitle: String?

    init(title: String, accent: Color = .accentColor, subtitle: String? = nil) {
        self.title = title
        self.accent = accent
        self.subtitle = subtitle
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))

            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(accent)
                    )
                    .accessibilityHidden(true)

                Text(title.isEmpty ? "Meditation" : title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(18)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Meditation cover for \(title.isEmpty ? "meditation" : title)")
    }

    private var gradient: [Color] {
        let seed = Double(abs(title.hashValue % 100)) / 100.0
        let base = accent.opacity(0.7)
        return [
            Color(hue: seed, saturation: 0.45, brightness: 0.95),
            base,
            Color(hue: seed + 0.1, saturation: 0.55, brightness: 0.75)
        ]
    }
}
