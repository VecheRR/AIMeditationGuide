//
//  OnboardingView.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        .init(
            title: "Welcome to\nAI Meditation",
            subtitle: "Personalized, soothing practices tailored to how you feel today.",
            icon: "sparkles",
            accent: Color.purple,
            highlights: [
                "Instantly generate guided meditations",
                "Designed to match your current mood"
            ]
        ),
        .init(
            title: "Breathing &\nRoutine Support",
            subtitle: "Guided breathing timers and daily practice plans keep you consistent.",
            icon: "wind",
            accent: Color.blue,
            highlights: [
                "Breathing exercises with calm pacing",
                "Routine tracker with small, daily steps"
            ]
        ),
        .init(
            title: "Immersive Audio",
            subtitle: "Pick the voice, background ambience, and session length you prefer.",
            icon: "headphones",
            accent: Color.green,
            highlights: [
                "Choose voices & ambient backgrounds",
                "Control voice and background volumes"
            ]
        ),
        .init(
            title: "Stay Mindful\nEvery Day",
            subtitle: "Track your progress and revisit your favorite sessions anytime.",
            icon: "leaf",
            accent: Color.orange,
            highlights: [
                "History of meditations & breathing",
                "One tap to replay or continue"
            ]
        )
    ]

    private var isLastPage: Bool { page == pages.count - 1 }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 18) {
                HStack {
                    Spacer()
                    Button("Skip") { onFinish() }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        OnboardingCard(page: item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageControl
                    .padding(.top, 4)

                PrimaryButton(title: isLastPage ? "START NOW" : "NEXT") {
                    if isLastPage {
                        onFinish()
                    } else {
                        withAnimation(.spring()) { page += 1 }
                    }
                }
                .padding(.top, 4)

                Button {
                    onFinish()
                } label: {
                    Text("I'll explore on my own")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .underline()
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }

    private var pageControl: some View {
        HStack(spacing: 10) {
            ForEach(pages.indices, id: \.self) { idx in
                Capsule()
                    .fill(idx == page ? Color.black : Color.black.opacity(0.18))
                    .frame(width: idx == page ? 28 : 10, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: page)
            }
        }
    }
}

private struct OnboardingCard: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                Circle()
                    .fill(page.accent.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .offset(x: 14, y: -10)
                    .blur(radius: 6)

                Circle()
                    .stroke(page.accent.opacity(0.3), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Image(systemName: page.icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(page.accent)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 10) {
                Text(page.title)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineSpacing(4)

                Text(page.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(page.highlights, id: \.self) { highlight in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(page.accent)
                            .font(.system(size: 16, weight: .bold))
                            .padding(.top, 2)
                        Text(highlight)
                            .font(.footnote)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .frame(height: 470)
        .background(Color.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let highlights: [String]
}
