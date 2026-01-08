//
//  GeneratedResultView.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 29.12.2025.
//

import SwiftUI
import SwiftData
import UIKit

struct GeneratedResultView: View {
    @ObservedObject var vm: GeneratorViewModel

    @State private var openPlayer = false
    @State private var bg: GenBackground = .nature
    @State private var didSave = false

    @State private var isStarting = false
    @State private var startError: String?

    @Environment(\.modelContext) private var modelContext

    // Language
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.system.rawValue
    private var lang: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .system }

    var body: some View {
        let title = vm.generated?.title ?? L10n.s("gen_result_default_title", lang: lang)
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
                        Text(L10n.s("gen_result_summary_title", lang: lang))
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)

                        Text(summary.isEmpty ? L10n.s("gen_result_summary_empty", lang: lang) : summary)
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
                        .accessibilityLabel(Text(accessibilitySummary(minutes: durationValue)))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.regularMaterial)
                    )
                    .padding(.horizontal, 16)

                    if let startError, !startError.isEmpty {
                        Text(startError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }

                    VStack(spacing: 12) {

                        PrimaryButton(
                            title: isStarting
                                ? L10n.s("paywall_processing", lang: lang)
                                : L10n.s("gen_result_btn_start", lang: lang)
                        ) {
                            Task { await startMeditationWithAd() }
                        }
                        .accessibilityLabel(Text(L10n.s("gen_result_a11y_start", lang: lang)))
                        .disabled(isStarting || vm.generated == nil)

                        PrimaryButton(title: L10n.s("gen_result_btn_save", lang: lang)) {
                            saveToHistory()
                            didSave = true
                        }
                        .accessibilityLabel(Text(L10n.s("gen_result_a11y_save", lang: lang)))
                        .disabled(didSave || vm.generated == nil)
                    }
                    .padding(.bottom, 20)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 18)
            }
        }
        .navigationTitle(L10n.s("gen_result_nav_title", lang: lang))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // заранее подгружаем rewarded
            AdMobRewardedManager.shared.preload()
        }
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

    // MARK: - Start with rewarded ad

    @MainActor
    private func startMeditationWithAd() async {
        startError = nil
        isStarting = true
        defer { isStarting = false }

        // подстраховка — если не подгружено
        AdMobRewardedManager.shared.preload()

        guard let vc = UIApplication.shared.topViewController else {
            startError = "No view controller to present ad."
            return
        }

        let ok = await AdMobRewardedManager.shared.show(from: vc)

        // ok = true только если reward получен (так и должно быть в твоём менеджере)
        guard ok else {
            startError = "Ad not completed. Try again."
            return
        }

        bg = vm.background ?? .none
        openPlayer = true
    }

    // MARK: - Labels

    private func coverSubtitle(minutes: Int) -> String {
        L10n.f("gen_result_cover_subtitle", lang: lang, minutes)
    }

    private func durationLabel(minutes: Int) -> String {
        L10n.f("gen_result_duration_short", lang: lang, minutes)
    }

    private func backgroundLabel() -> String {
        guard let bg = vm.background else {
            return L10n.s("gen_result_bg_none", lang: lang)
        }
        if bg == .none {
            return L10n.s("gen_result_bg_none", lang: lang)
        }
        return L10n.s("gen_bg_\(bg.rawValue)", lang: lang)
    }

    private func accessibilitySummary(minutes: Int) -> String {
        L10n.f("gen_result_a11y_duration_bg", lang: lang, minutes, backgroundLabel())
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
