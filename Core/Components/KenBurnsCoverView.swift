//
//  KenBurnsCoverView.swift
//  AIMeditationGuide
//
//  Created by ChatGPT on 2025-06-04.
//

import SwiftUI

struct KenBurnsCoverView: View {
    let imageURL: URL?
    let title: String
    let subtitle: String

    @State private var animate = false

    private let animation = Animation.easeInOut(duration: 18).repeatForever(autoreverses: true)

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .scaleEffect(animate ? 1.15 : 1.0)
                                .offset(x: animate ? -12 : 12, y: animate ? 12 : -12)
                                .clipped()
                                .animation(animation, value: animate)
                        case .failure:
                            placeholder
                        case .empty:
                            placeholder
                        @unknown default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [Color.black.opacity(0.0), Color.black.opacity(0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
                .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .onAppear {
            animate = true
        }
    }

    private var placeholder: some View {
        CoverPlaceholderView(title: title, accent: Color.purple, subtitle: subtitle)
    }
}

