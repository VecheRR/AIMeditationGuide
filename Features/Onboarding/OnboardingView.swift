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

    // Language (важно!)
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.system.rawValue
    private var lang: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .system }

    private let pages: [OnboardingPage] = [
        .init(
            titleKey: "onb_p1_title",
            subtitleKey: "onb_p1_subtitle",
            icon: "sparkles",
            accent: Color.purple,
            highlightKeys: ["onb_p1_h1", "onb_p1_h2"]
        ),
        .init(
            titleKey: "onb_p2_title",
            subtitleKey: "onb_p2_subtitle",
            icon: "wind",
            accent: Color.blue,
            highlightKeys: ["onb_p2_h1", "onb_p2_h2"]
        ),
        .init(
            titleKey: "onb_p3_title",
            subtitleKey: "onb_p3_subtitle",
            icon: "headphones",
            accent: Color.green,
            highlightKeys: ["onb_p3_h1", "onb_p3_h2"]
        ),
        .init(
            titleKey: "onb_p4_title",
            subtitleKey: "onb_p4_subtitle",
            icon: "leaf",
            accent: Color.orange,
            highlightKeys: ["onb_p4_h1", "onb_p4_h2"]
        )
    ]

    private var isLastPage: Bool { page == pages.count - 1 }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 18) {
                HStack {
                    Spacer()
                    Button(L10n.s("onb_skip", lang: lang)) { onFinish() }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        OnboardingCard(page: item, lang: lang)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageControl
                    .padding(.top, 4)

                PrimaryButton(
                    title: isLastPage
                        ? L10n.s("onb_start_now", lang: lang)
                        : L10n.s("onb_next", lang: lang)
                ) {
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
                    Text(L10n.s("onb_explore", lang: lang))
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
    let lang: AppLanguage

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
                Text(L10n.s(page.titleKey, lang: lang))
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineSpacing(4)

                Text(L10n.s(page.subtitleKey, lang: lang))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(page.highlightKeys, id: \.self) { key in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(page.accent)
                            .font(.system(size: 16, weight: .bold))
                            .padding(.top, 2)

                        Text(L10n.s(key, lang: lang))
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
    let titleKey: String
    let subtitleKey: String
    let icon: String
    let accent: Color
    let highlightKeys: [String]
}
