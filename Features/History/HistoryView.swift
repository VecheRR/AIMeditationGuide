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

    enum Segment: String, CaseIterable {
        case meditations = "MEDITATIONS"
        case breathing = "BREATHING"
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
                                    Button {
                                        selected = s
                                    } label: {
                                        historyCard(session: s)
                                    }
                                    .buttonStyle(.plain)
                                }
                                if sessions.isEmpty {
                                    Text("No meditation sessions yet")
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 30)
                                }
                            } else {
                                ForEach(breathingLogs) { log in
                                    breathingCard(log: log)
                                }
                                if breathingLogs.isEmpty {
                                    Text("No breathing sessions yet")
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
            .navigationTitle("HISTORY")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: Binding(
                get: { selected != nil },
                set: { if !$0 { selected = nil } }
            )) {
                if let selected {
                    MeditationPlayerView(session: selected)
                }
            }
            .alert("Delete meditation?", isPresented: Binding(
                get: { sessionToDelete != nil },
                set: { if !$0 { sessionToDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let sessionToDelete { modelContext.delete(sessionToDelete) }
                    sessionToDelete = nil
                }
                Button("Cancel", role: .cancel) { sessionToDelete = nil }
            } message: {
                if let sessionToDelete {
                    Text("Remove \(sessionToDelete.title) from history?")
                }
            }
            .alert("Delete breathing log?", isPresented: Binding(
                get: { breathingToDelete != nil },
                set: { if !$0 { breathingToDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let breathingToDelete { modelContext.delete(breathingToDelete) }
                    breathingToDelete = nil
                }
                Button("Cancel", role: .cancel) { breathingToDelete = nil }
            } message: {
                Text("Remove breathing entry from history?")
            }
        }
    }

    private var picker: some View {
        HStack(spacing: 0) {
            ForEach(Segment.allCases, id: \.self) { seg in
                Button {
                    segment = seg
                } label: {
                    Text(seg.rawValue)
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
                statCard(title: "Total minutes", value: "\(totalMeditationMinutes)", caption: "Meditations")
                statCard(title: "Daily streak", value: "\(streakDays)", caption: "days")
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack { 
                    Text("Weekly progress")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(weeklyMinutes) / 70 min")
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
                    Text("\(session.durationMinutes) MIN")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("\(session.durationMinutes) MINUTES")
                    .font(.headline)

                Text(session.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(session.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                sessionToDelete = session
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
                    .padding(10)
                    .background(Color.white.opacity(0.6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func breathingCard(log: BreathingLog) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.08))
                .frame(width: 64, height: 64)
                .overlay(
                    Text("\(log.durationSeconds / 60) MIN")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(log.mood)
                    .font(.headline)

                Text("Guided breathing")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text(log.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                breathingToDelete = log
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
                    .padding(10)
                    .background(Color.white.opacity(0.6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
