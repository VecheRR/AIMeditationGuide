//
//  GeneratedResultView.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 29.12.2025.
//

import SwiftUI
import SwiftData

struct GeneratedResultView: View {
    @ObservedObject var vm: GeneratorViewModel

    @State private var openPlayer = false
    @State private var bg: GenBackground = .nature
    @State private var didSave = false

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        let title = vm.generated?.title ?? String(localized: "gen_result_default_title")
        let summary = vm.generated?.summary ?? ""
        let durationValue = vm.duration?.rawValue ?? 5

        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 18) {
                    KenBurnsCoverView(
                        imageURL: vm.coverImageURL,
                        title: title,
                        subtitle: coverSubtitle(minutes: durationValue)
                    )
                    .frame(height: 220)
                    .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "gen_result_summary_title"))
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)

                        Text(summary.isEmpty ? String(localized: "gen_result_summary_empty") : summary)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        HStack {
                            Label(durationLabel(minutes: durationValue), systemImage: "clock")
                            Label(backgroundLabel(), systemImage: "music.note")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(accessibilitySummary(minutes: durationValue))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.regularMaterial)
                    )
                    .padding(.horizontal, 16)

                    VStack(spacing: 12) {
                        PrimaryButton(title: String(localized: "gen_result_btn_start")) {
                            bg = vm.background ?? .none
                            openPlayer = true
                        }
                        .accessibilityLabel(Text(String(localized: "gen_result_a11y_start")))

                        PrimaryButton(title: String(localized: "gen_result_btn_save")) {
                            saveToHistory()
                            didSave = true
                        }
                        .accessibilityLabel(Text(String(localized: "gen_result_a11y_save")))
                        .disabled(didSave || vm.generated == nil)
                    }
                    .padding(.bottom, 20)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 18)
            }
        }
        .navigationTitle(String(localized: "gen_result_nav_title"))
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $openPlayer) {
            PlayerView(
                title: title,
                summary: summary,
                durationMinutes: durationValue,
                voiceURL: vm.voiceFileURL,
                coverURL: vm.coverImageURL,
                background: $bg,
                onSave: {
                    saveToHistory()
                    didSave = true
                },
                isAlreadySaved: didSave,
                onFinishEarly: { openPlayer = false }
            )
        }
    }

    // MARK: - Localized strings helpers

    private func coverSubtitle(minutes: Int) -> String {
        // "%lld min guided session"
        return String(format: String(localized: "gen_result_cover_subtitle"), minutes)
    }

    private func durationLabel(minutes: Int) -> String {
        // "%lld min"
        return String(format: String(localized: "gen_result_duration_short"), minutes)
    }

    private func backgroundLabel() -> String {
        // Если у тебя rawValue на английском — это временно ок.
        // Потом лучше сделать локализуемые title для enum.
        let bgName = vm.background?.rawValue ?? String(localized: "gen_result_bg_none")
        return bgName
    }

    private func accessibilitySummary(minutes: Int) -> String {
        let bgName = vm.background?.rawValue ?? String(localized: "gen_result_bg_none")
        // "Duration %lld minutes. Background %@"
        return String(format: String(localized: "gen_result_a11y_duration_bg"), minutes, bgName)
    }

    // MARK: - Save

    private func saveToHistory() {
        guard let gen = vm.generated else { return }
        let minutes = vm.duration?.rawValue ?? 5
        let bgRaw = (vm.background ?? .none).rawValue
        let fileName = vm.voiceFileURL?.lastPathComponent
        let voicePath = vm.voiceFileURL?.path
        let backgroundPath = SoundLibrary.url(for: vm.background ?? .none)?.path

        let session = MeditationSession(
            durationMinutes: minutes,
            title: gen.title,
            summary: gen.summary,
            script: gen.script,
            voiceFileName: fileName,
            voiceFilePath: voicePath,
            backgroundRaw: bgRaw,
            backgroundFilePath: backgroundPath,
            coverImageURLString: vm.coverImageURL?.absoluteString
        )

        modelContext.insert(session)
    }
}
