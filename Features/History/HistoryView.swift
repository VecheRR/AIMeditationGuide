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
    @State private var playbackBackground: GenBackground = .none

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

                    ScrollView {
                        VStack(spacing: 10) {
                            if segment == .meditations {
                                ForEach(sessions) { s in
                                    Button {
                                        selected = s
                                        playbackBackground = s.background
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
                    PlayerView(
                        title: selected.title,
                        summary: selected.summary,
                        durationMinutes: selected.durationMinutes,
                        voiceURL: selected.voiceURL,
                        storedBackground: selected.background,
                        backgroundFileURL: selected.backgroundURL,
                        background: $playbackBackground
                    )
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

                Text(session.createdAt, style: .date)
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

                Text(log.createdAt, style: .date)
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
