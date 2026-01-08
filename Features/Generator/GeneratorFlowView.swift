//
//  GeneratorFlowView.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI

struct GeneratorFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = GeneratorViewModel()

    // Language (важно!)
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.system.rawValue
    private var lang: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .system }

    @State private var showGoal = false
    @State private var showDuration = false
    @State private var showVoice = false
    @State private var showBg = false
    @State private var showResult = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 56, weight: .semibold))
                                .padding(.top, 6)

                            Text(L10n.s("gen_flow_hint", lang: lang))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 12) {
                            row(
                                title: L10n.s("gen_goal_title", lang: lang),
                                valueText: vm.goal.map { goalTitle($0) } ?? ""
                            ) { showGoal = true }

                            row(
                                title: L10n.s("gen_duration_title", lang: lang),
                                valueText: vm.duration.map { durationTitle($0) } ?? ""
                            ) { showDuration = true }

                            row(
                                title: L10n.s("gen_voice_title", lang: lang),
                                valueText: vm.voice.map { voiceTitle($0) } ?? ""
                            ) { showVoice = true }

                            row(
                                title: L10n.s("gen_bg_title", lang: lang),
                                valueText: vm.background.map { bgTitle($0) } ?? ""
                            ) { showBg = true }
                        }
                        .padding(.horizontal, 16)

                        if let err = vm.errorText {
                            Text(err) // системное
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 24)
                }

                VStack {
                    Spacer()

                    PrimaryButton(
                        title: vm.isLoading
                            ? L10n.s("gen_btn_generating", lang: lang)
                            : L10n.s("gen_btn_generate", lang: lang),
                        isEnabled: vm.canGenerate && !vm.isLoading
                    ) {
                        Task {
                            await vm.generate()
                            if vm.generated != nil { showResult = true }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle(L10n.s("gen_nav_title", lang: lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel(Text(L10n.s("common_close", lang: lang)))
                }
            }
            .navigationDestination(isPresented: $showResult) {
                GeneratedResultView(vm: vm)
            }

            // MARK: - Sheets (ID хранится rawValue, UI показывает локализованный title)

            .sheet(isPresented: $showGoal) {
                SelectList(
                    title: L10n.s("gen_sheet_goal_title", lang: lang),
                    rows: GenGoal.allCases.map {
                        .init(id: $0.rawValue, title: goalTitle($0))
                    },
                    selectedID: vm.goal?.rawValue
                ) { id in
                    vm.goal = GenGoal(rawValue: id)
                }
                .presentationDetents([.medium])
            }

            .sheet(isPresented: $showDuration) {
                SelectList(
                    title: L10n.s("gen_sheet_duration_title", lang: lang),
                    rows: GenDuration.allCases.map {
                        .init(id: String($0.rawValue), title: durationTitle($0))
                    },
                    selectedID: vm.duration.map { String($0.rawValue) }
                ) { id in
                    if let raw = Int(id) {
                        vm.duration = GenDuration(rawValue: raw)
                    }
                }
                .presentationDetents([.medium])
            }

            .sheet(isPresented: $showVoice) {
                SelectList(
                    title: L10n.s("gen_sheet_voice_title", lang: lang),
                    rows: GenVoice.allCases.map {
                        .init(id: $0.rawValue, title: voiceTitle($0))
                    },
                    selectedID: vm.voice?.rawValue
                ) { id in
                    vm.voice = GenVoice(rawValue: id)
                }
                .presentationDetents([.medium])
            }

            .sheet(isPresented: $showBg) {
                SelectList(
                    title: L10n.s("gen_sheet_bg_title", lang: lang),
                    rows: GenBackground.allCases.map {
                        .init(id: $0.rawValue, title: bgTitle($0))
                    },
                    selectedID: vm.background?.rawValue
                ) { id in
                    vm.background = GenBackground(rawValue: id)
                }
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Row

    private func row(title: String, valueText: String, action: @escaping () -> Void) -> some View {
        let displayValue = valueText.isEmpty ? L10n.s("gen_row_tap_to_choose", lang: lang) : valueText
        let a11yValue = valueText.isEmpty ? L10n.s("gen_row_not_selected", lang: lang) : valueText

        return Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(displayValue)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.body.weight(.semibold))
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08))
            )
        }
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .accessibilityLabel(Text("\(title). \(a11yValue)"))
    }

    // MARK: - Localized enum titles (UI)

    private func goalTitle(_ g: GenGoal) -> String {
        // ожидаем ключи вида: gen_goal_reduce_stress и т.д.
        L10n.s("gen_goal_\(g.rawValue)", lang: lang)
    }

    private func voiceTitle(_ v: GenVoice) -> String {
        L10n.s("gen_voice_\(v.rawValue)", lang: lang)
    }

    private func bgTitle(_ b: GenBackground) -> String {
        L10n.s("gen_bg_\(b.rawValue)", lang: lang)
    }

    private func durationTitle(_ d: GenDuration) -> String {
        // ожидаем ключи: gen_duration_5 / gen_duration_10 / gen_duration_15
        L10n.s("gen_duration_\(d.rawValue)", lang: lang)
    }
}
