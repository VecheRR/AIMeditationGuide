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

                            Text("Fill in the details below to\ngenerate a meditation")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 12) {
                            row(title: "Meditation Goal", value: vm.goal?.rawValue ?? "") { showGoal = true }
                            row(title: "Duration", value: vm.duration?.title ?? "") { showDuration = true }
                            row(title: "Voice Style", value: vm.voice?.rawValue ?? "") { showVoice = true }
                            row(title: "Background Sound", value: vm.background?.rawValue ?? "") { showBg = true }
                        }
                        .padding(.horizontal, 16)

                        if let err = vm.errorText {
                            Text(err)
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
                        title: vm.isLoading ? "GENERATING..." : "GENERATE",
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
            .navigationTitle("GENERATE MEDITATION")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
            .navigationDestination(isPresented: $showResult) {
                GeneratedResultView(vm: vm)
            }
            .sheet(isPresented: $showGoal) {
                SelectList(
                    title: "MEDITATION GOAL",
                    items: GenGoal.allCases.map { $0.rawValue },
                    selected: vm.goal?.rawValue
                ) { v in vm.goal = GenGoal(rawValue: v) }
            }
            .sheet(isPresented: $showDuration) {
                SelectList(
                    title: "DURATION",
                    items: GenDuration.allCases.map { $0.title },
                    selected: vm.duration?.title
                ) { v in vm.duration = GenDuration.allCases.first(where: { $0.title == v }) }
            }
            .sheet(isPresented: $showVoice) {
                SelectList(
                    title: "VOICE STYLE",
                    items: GenVoice.allCases.map { $0.rawValue },
                    selected: vm.voice?.rawValue
                ) { v in vm.voice = GenVoice(rawValue: v) }
            }
            .sheet(isPresented: $showBg) {
                SelectList(
                    title: "BACKGROUND SOUND",
                    items: GenBackground.allCases.map { $0.rawValue },
                    selected: vm.background?.rawValue
                ) { v in vm.background = GenBackground(rawValue: v) }
            }
        }
    }

    private func row(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(value.isEmpty ? "Tap to choose" : value)
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
        .accessibilityLabel(Text("\(title). \(value.isEmpty ? "Not selected" : value)"))
    }
}
