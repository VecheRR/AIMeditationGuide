//
//  HistoryView.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 29.12.2025.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MeditationSession.createdAt, order: .reverse) private var sessions: [MeditationSession]
    @Query(sort: \BreathingLog.createdAt, order: .reverse) private var breathingLogs: [BreathingLog]

    // Language (важно!)
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.system.rawValue
    private var lang: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .system }

    @State private var segment: Segment = .meditations

    @State private var selected: MeditationSession?
    @State private var sessionToDelete: MeditationSession?
    @State private var breathingToDelete: BreathingLog?

    private var totalMeditationMinutes: Int {
        sessions.reduce(into: 0) { $0 += $1.durationMinutes }
    }

    private var weeklyMinutes: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -6, to: .now) ?? .now
        return sessions
            .filter { $0.createdAt >= weekAgo }
            .reduce(into: 0) { $0 += $1.durationMinutes }
    }

    private var streakDays: Int {
        let calendar = Calendar.current
        let grouped = Set(sessions.map { calendar.startOfDay(for: $0.createdAt) })
        var streak = 0
        var current = calendar.startOfDay(for: .now)

        while grouped.contains(current) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: current) else { break }
            current = prev
        }

        return streak
    }

    enum Segment: CaseIterable, Hashable {
        case meditations
        case breathing

        var titleKey: String {
            switch self {
            case .meditations: return "history_segment_meditations"
            case .breathing:   return "history_segment_breathing"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 12) {
                    picker
                    stats

                    ScrollView {
                        VStack(spacing: 10) {
                            if segment == .meditations {
                                ForEach(sessions) { s in
                                    Button { selected = s } label: {
                                        historyCard(session: s)
                                    }
                                    .buttonStyle(.plain)
                                }

                                if sessions.isEmpty {
                                    Text(L10n.s("history_empty_meditations", lang: lang))
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 30)
                                }
                            } else {
                                ForEach(breathingLogs) { log in
                                    breathingCard(log: log)
                                }

                                if breathingLogs.isEmpty {
                                    Text(L10n.s("history_empty_breathing", lang: lang))
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 30)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle(L10n.s("history_title", lang: lang))
            .navigationBarTitleDisplayMode(.inline)

            // open meditation
            .fullScreenCover(isPresented: Binding(
                get: { selected != nil },
                set: { if !$0 { selected = nil } }
            )) {
                if let selected {
                    MeditationPlayerView(session: selected)
                }
            }

            // delete meditation alert
            .alert(L10n.s("history_delete_meditation_title", lang: lang), isPresented: Binding(
                get: { sessionToDelete != nil },
                set: { if !$0 { sessionToDelete = nil } }
            )) {
                Button(L10n.s("common_delete", lang: lang), role: .destructive) {
                    if let sessionToDelete { modelContext.delete(sessionToDelete) }
                    sessionToDelete = nil
                }
                Button(L10n.s("common_cancel", lang: lang), role: .cancel) {
                    sessionToDelete = nil
                }
            } message: {
                if let sessionToDelete {
                    Text(L10n.f("history_delete_meditation_message_format", lang: lang, sessionToDelete.title))
                }
            }

            // delete breathing alert
            .alert(L10n.s("history_delete_breathing_title", lang: lang), isPresented: Binding(
                get: { breathingToDelete != nil },
                set: { if !$0 { breathingToDelete = nil } }
            )) {
                Button(L10n.s("common_delete", lang: lang), role: .destructive) {
                    if let breathingToDelete { modelContext.delete(breathingToDelete) }
                    breathingToDelete = nil
                }
                Button(L10n.s("common_cancel", lang: lang), role: .cancel) {
                    breathingToDelete = nil
                }
            } message: {
                Text(L10n.s("history_delete_breathing_message", lang: lang))
            }
        }
        .onAppear { Analytics.screen("history") }
    }

    private var picker: some View {
        HStack(spacing: 0) {
            ForEach(Segment.allCases, id: \.self) { seg in
                Button { segment = seg } label: {
                    Text(L10n.s(seg.titleKey, lang: lang))
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(segment == seg ? Color.black : Color.white.opacity(0.6))
                        .foregroundStyle(segment == seg ? .white : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var stats: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                statCard(
                    title: L10n.s("history_stat_total_minutes_title", lang: lang),
                    value: "\(totalMeditationMinutes)",
                    caption: L10n.s("history_stat_total_minutes_caption", lang: lang)
                )
                statCard(
                    title: L10n.s("history_stat_streak_title", lang: lang),
                    value: "\(streakDays)",
                    caption: L10n.s("history_stat_streak_caption", lang: lang)
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(L10n.s("history_weekly_progress_title", lang: lang))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(L10n.f("history_weekly_progress_value_format", lang: lang, weeklyMinutes))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: min(Double(weeklyMinutes) / 70.0, 1.0))
                    .tint(.green)
            }
            .padding(12)
            .background(Color.white.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private func statCard(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
            Text(caption)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func historyCard(session: MeditationSession) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.08))
                .frame(width: 64, height: 64)
                .overlay(
                    Text(L10n.f("history_minutes_badge_format", lang: lang, session.durationMinutes))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.f("history_minutes_title_format", lang: lang, session.durationMinutes))
                    .font(.headline)

                Text(session.summary.isEmpty ? L10n.s("history_meditation_summary_fallback", lang: lang) : session.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(session.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button { sessionToDelete = session } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
                    .padding(10)
                    .background(Color.white.opacity(0.6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.s("common_delete", lang: lang))
        }
        .padding(12)
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func breathingCard(log: BreathingLog) -> some View {
        let minutes = log.durationSeconds / 60

        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.08))
                .frame(width: 64, height: 64)
                .overlay(
                    Text(L10n.f("history_minutes_badge_format", lang: lang, minutes))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(localizedMoodTitle(log.moodTitle))
                    .font(.headline)

                Text(L10n.s("history_breathing_subtitle", lang: lang))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(log.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button { breathingToDelete = log } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
                    .padding(10)
                    .background(Color.white.opacity(0.6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.s("common_delete", lang: lang))
        }
        .padding(12)
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func localizedMoodTitle(_ raw: String) -> String {
        // raw у тебя сейчас "Calm"/"Neutral"/"Stressed"/"Anxious"
        // если придёт что-то другое — покажем как есть
        switch raw.lowercased() {
        case "calm":     return L10n.s("bre_mood_calm", lang: lang)
        case "neutral":  return L10n.s("bre_mood_neutral", lang: lang)
        case "stressed": return L10n.s("bre_mood_stressed", lang: lang)
        case "anxious":  return L10n.s("bre_mood_anxious", lang: lang)
        default:         return raw
        }
    }
}
