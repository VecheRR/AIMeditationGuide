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

    @State private var segment: Segment = .meditations

    @State private var selected: MeditationSession?
    @State private var openPlayer = false
    @State private var bg: GenBackground = .none

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
                                        bg = s.background
                                        openPlayer = true
                                    } label: {
                                        historyCard(session: s)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                Text("Breathing history позже")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 30)
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
            .fullScreenCover(isPresented: $openPlayer) {
                PlayerView(
                    title: selected?.title ?? "Meditation",
                    summary: selected?.summary ?? "",
                    durationMinutes: selected?.durationMinutes ?? 5,
                    voiceURL: selected?.voiceURL,
                    background: $bg
                )
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
                modelContext.delete(session)
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
