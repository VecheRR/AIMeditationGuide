//
//  HomeView.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 29.12.2025.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \MeditationSession.createdAt, order: .reverse)
    private var sessions: [MeditationSession]
    @Query(sort: \RoutinePlan.createdAt, order: .reverse)
    private var routines: [RoutinePlan]

    @State private var goBreathing = false
    @State private var goRoutine = false
    @State private var showGenerator = false

    // Player
    @State private var openPlayer = false
    @State private var playerSession: MeditationSession?
    @State private var bg: GenBackground = .none

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

                VStack(alignment: .leading, spacing: 14) {
                    Spacer().frame(height: 10)

                    Text("Hello, Vitalii")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("How are you\nfeeling today?")
                        .font(.system(size: 34, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .center)

                    miniSuggestion

                    VStack(spacing: 10) {
                        actionButton(title: "GENERATE MEDITATION", icon: "sparkles") { showGenerator = true }
                        actionButton(title: "BREATHING EXERCISE", icon: "wind") { goBreathing = true }
                        actionButton(title: "DAILY ROUTINE", icon: "leaf") { goRoutine = true }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)

                    if let latestRoutine {
                        routineCard(plan: latestRoutine, next: nextPractice)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                    } else {
                        routineSuggestionCard
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                    }

                    if let last {
                        todayCard(last)
                            .padding(.horizontal, 16)
                            .padding(.top, 6)
                    }

                    Spacer()
                }
            }
            .navigationDestination(isPresented: $goBreathing) {
                BreathingSetupView()
            }
            .navigationDestination(isPresented: $goRoutine) {
                RoutineView()
            }
            .fullScreenCover(isPresented: $showGenerator) {
                GeneratorFlowView()
            }
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
        }
    }

    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .frame(width: 22)
                Text(title)
                    .font(.caption.bold())
                Spacer()
            }
            .foregroundStyle(.black)
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(Color.white.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var miniSuggestion: some View {
        let suggestion = miniRecommendation()

        return HStack(alignment: .center, spacing: 12) {
            Image(systemName: "lightbulb")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 4) {
                Text("AI suggestion")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(suggestion)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func todayCard(_ s: MeditationSession) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today's Meditation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(s.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.black.opacity(0.08))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Text("\(s.durationMinutes) MIN")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(s.durationMinutes) MINUTES")
                        .font(.headline)
                    Text(s.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(spacing: 8) {
                    Button {
                        open(session: s)
                    } label: {
                        Text("CONTINUE")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.65))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        replay(session: s)
                    } label: {
                        Text("REPLAY")
                            .font(.caption.bold())
                            .foregroundStyle(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.65))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func open(session: MeditationSession) {
        playerSession = session
        bg = session.background
        openPlayer = true
    }

    private func replay(session: MeditationSession) {
        // Пока делаем как "open", но если захочешь, можно прокинуть флаг
        // и в AudioPlayerService делать seek(0) на onAppear.
        playerSession = session
        bg = session.background
        openPlayer = true
    }

    private func miniRecommendation() -> String {
        if let nextPractice {
            return "Next up: \(nextPractice.title) — take \(nextPractice.durationMinutes) minutes to keep your routine on track."
        }

        if let last {
            return "Great job completing a \(last.durationMinutes)-minute session. Try a quick 5-minute breathing break to stay balanced."
        }

        return "Start with a 5-minute session to set your intention, then follow with a calming breathing exercise."
    }

    private func routineCard(plan: RoutinePlan, next: RoutineItem?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Daily Routine")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(plan.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                if plan.status == .done {
                    Text("Routine completed")
                        .font(.headline)
                    Text("Regenerate a new set when you'd like another gentle nudge.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if let next {
                    Text(next.title)
                        .font(.headline)
                    Text("\(next.durationMinutes) min • \(next.details)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else {
                    Text("All practices completed")
                        .font(.headline)
                    Text("Feel free to regenerate a new flow when you're ready.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                goRoutine = true
            } label: {
                Text(plan.status == .done ? "GENERATE NEW" : (next == nil ? "VIEW ROUTINE" : "START NEXT"))
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var routineSuggestionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Routine")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("No routine yet")
                .font(.headline)
            Text("Generate 1–3 quick practices to keep your habit alive today.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                goRoutine = true
            } label: {
                Text("CREATE ROUTINE")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
