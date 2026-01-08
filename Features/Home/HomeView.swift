//
//  HomeView.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 29.12.2025.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    // Data
    @Query(sort: \MeditationSession.createdAt, order: .reverse)
    private var sessions: [MeditationSession]
    @Query(sort: \RoutinePlan.createdAt, order: .reverse)
    private var routines: [RoutinePlan]

    // Navigation
    @State private var goBreathing = false
    @State private var goRoutine = false
    @State private var showGenerator = false

    // Player
    @State private var openPlayer = false
    @State private var playerSession: MeditationSession?
    @State private var bg: GenBackground = .none

    // Name
    @AppStorage("userName") private var userName: String = ""
    @State private var showNamePrompt = false

    // Language (важно!)
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.system.rawValue
    private var lang: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .system }

    // Derived
    private var last: MeditationSession? { sessions.first }
    private var latestRoutine: RoutinePlan? { routines.first }
    private var nextPractice: RoutineItem? {
        guard let plan = routines.first, plan.status != .done else { return nil }
        return plan.nextIncomplete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 18) {
                        header
                        quickActionsCard

                        if let last {
                            todaySection(last)
                        }

                        recommendedSection

                        Spacer().frame(height: 18)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $goBreathing) { BreathingSetupView() }
            .navigationDestination(isPresented: $goRoutine) { RoutineView() }
            .fullScreenCover(isPresented: $showGenerator) { GeneratorFlowView() }
            .fullScreenCover(isPresented: $openPlayer) {
                PlayerView(
                    title: playerSession?.title ?? L10n.s("common_meditation_default_title", lang: lang),
                    summary: playerSession?.summary ?? "",
                    durationMinutes: playerSession?.durationMinutes ?? 5,
                    voiceURL: playerSession?.voiceURL,
                    coverURL: playerSession?.coverURL,
                    background: $bg,
                    onSave: nil,
                    isAlreadySaved: true,
                    onFinishEarly: { openPlayer = false }
                )
            }
            .onAppear {
                if userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    showNamePrompt = true
                }
            }
            .sheet(isPresented: $showNamePrompt) {
                NamePromptView(name: $userName)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear { Analytics.screen("home") }
    }
}

// MARK: - UI blocks
private extension HomeView {

    var backgroundLayer: some View {
        AppBackground()
            .overlay(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.12),
                        Color.purple.opacity(0.08),
                        Color.yellow.opacity(0.08),
                        Color.white.opacity(0.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .ignoresSafeArea()
    }

    var header: some View {
        VStack(spacing: 8) {
            greetingText
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.black.opacity(0.55))
                .padding(.top, 6)

            Text(L10n.s("home_header_title", lang: lang))
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.black)
                .minimumScaleFactor(0.75)
                .lineLimit(2)
        }
    }

    var quickActionsCard: some View {
        VStack(spacing: 10) {
            actionRow(titleKey: "home_action_generate", icon: "sparkles", tint: .purple) {
                showGenerator = true
            }
            actionRow(titleKey: "home_action_breathing", icon: "wind", tint: .blue) {
                goBreathing = true
            }
            actionRow(titleKey: "home_action_routine", icon: "leaf", tint: .green) {
                goRoutine = true
            }
        }
        .padding(14)
        .background(glassCard)
    }

    func todaySection(_ s: MeditationSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.s("home_today_title", lang: lang))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)

                Spacer()

                // ВАЖНО: локаль для этого текста будет системной, пока ты не задашь .environment(\.locale, ...)
                Text(s.createdAt, style: .date)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.black.opacity(0.55))
            }

            todayCard(s)
        }
        .padding(.top, 6)
    }

    func todayCard(_ s: MeditationSession) -> some View {
        Button {
            open(session: s)
        } label: {
            HStack(spacing: 14) {
                coverThumb(for: s)
                    .frame(width: 78, height: 78)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.f("home_minutes_format_caps", lang: lang, s.durationMinutes))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)

                    Text(s.summary.isEmpty ? L10n.s("home_today_fallback_summary", lang: lang) : s.summary)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.black.opacity(0.6))
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Image(systemName: "leaf")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.green)

                        Text(latestRoutine != nil
                             ? L10n.s("home_badge_daily_routine", lang: lang)
                             : L10n.s("home_badge_meditation", lang: lang))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.75))
            )
        }
        .buttonStyle(.plain)
    }

    var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.s("home_recommended_title", lang: lang))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.black)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    recommendedCard(
                        titleKey: "home_rec_breathing_title",
                        subtitle: L10n.s("home_rec_breathing_subtitle", lang: lang),
                        icon: "wind",
                        tint: .blue
                    ) { goBreathing = true }

                    recommendedCard(
                        titleKey: "home_rec_routine_title",
                        subtitle: nextPracticeSubtitle,
                        icon: "leaf",
                        tint: .green
                    ) { goRoutine = true }

                    recommendedCard(
                        titleKey: "home_rec_meditation_title",
                        subtitle: L10n.s("home_rec_meditation_subtitle", lang: lang),
                        icon: "sparkles",
                        tint: .purple
                    ) { showGenerator = true }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.top, 6)
    }

    var nextPracticeSubtitle: String {
        if let nextPractice {
            return L10n.f("home_next_practice_format", lang: lang, nextPractice.durationMinutes, nextPractice.title)
        }
        if let latestRoutine, latestRoutine.status == .done {
            return L10n.s("home_routine_completed_subtitle", lang: lang)
        }
        return L10n.s("home_routine_fallback_subtitle", lang: lang)
    }

    func recommendedCard(titleKey: String, subtitle: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)

                    // ВАЖНО: не делаем .uppercased() “в лоб” — иначе RU выглядит по-дурацки + зависит от системной локали.
                    Text(uppercaseUI(L10n.s(titleKey, lang: lang)))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.7))

                    Spacer()
                }

                Text(subtitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .frame(width: 170, height: 110)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white.opacity(0.72))
            )
        }
        .buttonStyle(.plain)
    }

    func actionRow(titleKey: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.12))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                }

                Text(L10n.s(titleKey, lang: lang))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black)

                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.7))
            )
        }
        .buttonStyle(.plain)
    }

    var glassCard: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(Color.white.opacity(0.55))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
    }

    func coverThumb(for s: MeditationSession) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.08))

            if let url = s.coverURL {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Color.black.opacity(0.05)
                }
            }

            VStack {
                Spacer()
                Text(L10n.f("home_minutes_badge_format", lang: lang, s.durationMinutes))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Capsule())
                    .padding(8)
            }
        }
    }

    private var greetingText: some View {
        let n = userName.trimmingCharacters(in: .whitespacesAndNewlines)

        return Group {
            if n.isEmpty {
                Text(L10n.s("home_greeting_hello", lang: lang))
            } else {
                Text(L10n.f("home_greeting_named_format", lang: lang, n))
            }
        }
    }

    // MARK: - Helpers

    func open(session: MeditationSession) {
        playerSession = session
        bg = session.background
        openPlayer = true
    }

    func uppercaseUI(_ s: String) -> String {
        // В RU верхний регистр часто выглядит хуже (особенно в UI-лейблах).
        // Для EN оставляем uppercase.
        switch lang {
        case .ru:
            return s
        case .en:
            return s.uppercased(with: Locale(identifier: "en_US"))
        case .system:
            return s.uppercased() // как было, по системной локали
        }
    }
}
