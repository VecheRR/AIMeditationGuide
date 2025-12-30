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
                AppBackground()

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
                    title: playerSession?.title ?? "Meditation",
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
    }
}

// MARK: - UI blocks
private extension HomeView {

    var header: some View {
        VStack(spacing: 8) {
            greetingText
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundStyle(.black.opacity(0.75))
                .padding(.top, 6)

            // "How are you" — serif italic
            // "feeling" — жирный sans
            // "today?" — serif italic
            HStack(spacing: 8) {
                Text("How are you")
                    .font(.custom("Amstelvar-Italic", size: 48))
                    .kerning(-1.5)
                    .foregroundStyle(.black)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Text("feeling")
                    .font(.custom("FunnelDisplay-Regular", size: 48))
                    .kerning(-1.5)
                    .foregroundStyle(.black)

                Text("today?")
                    .font(.custom("Amstelvar-Italic", size: 48))
                    .kerning(-1.5)
                    .foregroundStyle(.black)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    var quickActionsCard: some View {
        VStack(spacing: 10) {
            actionRow(title: "GENERATE MEDITATION", icon: "sparkles", tint: .purple) {
                showGenerator = true
            }
            actionRow(title: "BREATHING EXERCISE", icon: "wind", tint: .blue) {
                goBreathing = true
            }
            actionRow(title: "DAILY ROUTINE", icon: "leaf", tint: .green) {
                goRoutine = true
            }
        }
        .padding(14)
        .background(glassCard)
    }

    func todaySection(_ s: MeditationSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today’s Meditation")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)

                Spacer()

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
                    Text("\(s.durationMinutes) MINUTES")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)

                    Text(s.summary.isEmpty ? "Take a quick meditation break" : s.summary)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.black.opacity(0.6))
                        .lineLimit(2)

                    // маленький бейдж как на макете
                    HStack(spacing: 8) {
                        Image(systemName: "leaf")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.green)

                        Text(latestRoutine != nil ? "DAILY ROUTINE" : "MEDITATION")
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
            Text("Recommended Sessions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.black)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Заглушки, пока у тебя нет массива рекомендаций
                    recommendedCard(title: "Breathing", subtitle: "3 min reset", icon: "wind", tint: .blue) {
                        goBreathing = true
                    }
                    recommendedCard(title: "Routine", subtitle: nextPracticeSubtitle, icon: "leaf", tint: .green) {
                        goRoutine = true
                    }
                    recommendedCard(title: "Meditation", subtitle: "5 min focus", icon: "sparkles", tint: .purple) {
                        showGenerator = true
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.top, 6)
    }

    var nextPracticeSubtitle: String {
        if let nextPractice {
            return "\(nextPractice.durationMinutes) min • \(nextPractice.title)"
        }
        if let latestRoutine, latestRoutine.status == .done {
            return "Completed • generate new"
        }
        return "1–3 practices"
    }

    func recommendedCard(title: String, subtitle: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)

                    Text(title.uppercased())
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

    func actionRow(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
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

                Text(title)
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
                Text("\(s.durationMinutes) MIN")
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
                Text("Hello")
                    .font(.custom("Amstelvar-Italic", size: 20))
                    .foregroundStyle(.secondary)
            } else {
                (
                    Text("Hello, ")
                        .font(.custom("Amstelvar-Italic", size: 20))
                        .foregroundStyle(.secondary)
                    +
                    Text(n)
                        .font(.custom("FunnelDisplay-Bold", size: 20))
                        .foregroundStyle(.secondary)
                )
            }
        }
    }

    func open(session: MeditationSession) {
        playerSession = session
        bg = session.background
        openPlayer = true
    }
}
