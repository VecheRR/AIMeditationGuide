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
        let title = vm.generated?.title ?? "Meditation"
        let summary = vm.generated?.summary ?? ""
        let durationValue = vm.duration?.rawValue ?? 5

        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 18) {
                    KenBurnsCoverView(
                        imageURL: vm.coverImageURL,
                        title: title,
                        subtitle: "\(durationValue) min guided session"
                    )
                    .frame(height: 220)
                    .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("SUMMARY")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)

                        Text(summary.isEmpty ? "Your meditation script will appear here." : summary)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)

                        HStack {
                            Label("\(durationValue) min", systemImage: "clock")
                            Label(vm.background?.rawValue ?? "No background", systemImage: "music.note")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Duration \(durationValue) minutes. Background \(vm.background?.rawValue ?? "No background")")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.regularMaterial)
                    )
                    .padding(.horizontal, 16)

                    VStack(spacing: 12) {
                        PrimaryButton(title: "START") {
                            bg = vm.background ?? .none
                            openPlayer = true
                        }
                        .accessibilityLabel("Start meditation")

                        PrimaryButton(title: "SAVE TO HISTORY") {
                            saveToHistory()
                            didSave = true
                        }
                        .accessibilityLabel("Save meditation to history")
                        .disabled(didSave || vm.generated == nil)
                    }
                    .padding(.bottom, 20)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("MEDITATION")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $openPlayer) {
            PlayerView(
                title: title,
                summary: summary,
                durationMinutes: vm.duration?.rawValue ?? 5,
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
