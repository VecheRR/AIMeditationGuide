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

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 14) {
                Spacer().frame(height: 10)

                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.12))
                    .frame(height: 180)
                    .overlay(Text("Cover").font(.headline).foregroundStyle(.secondary))

                VStack(alignment: .leading, spacing: 8) {
                    Text("\((vm.duration?.rawValue ?? 0)) MINUTES")
                        .font(.headline)

                    Text(vm.generated?.summary ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(vm.duration?.rawValue ?? 0) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

                Spacer()

                PrimaryButton(title: "START") {
                    bg = vm.background ?? .nature
                    openPlayer = true
                }

                PrimaryButton(title: "SAVE TO HISTORY") {
                    saveToHistory()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .navigationTitle("MEDITATION")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $openPlayer) {
            PlayerView(
                title: vm.generated?.title ?? "Meditation",
                summary: vm.generated?.summary ?? "",
                durationMinutes: vm.duration?.rawValue ?? 5,
                voiceURL: vm.voiceFileURL,
                background: $bg
            )
        }
    }

    private func saveToHistory() {
        guard let gen = vm.generated else { return }
        let minutes = vm.duration?.rawValue ?? 5
        let bgRaw = (vm.background ?? .none).rawValue
        let fileName = vm.voiceFileURL?.lastPathComponent

        let session = MeditationSession(
            durationMinutes: minutes,
            title: gen.title,
            summary: gen.summary,
            script: gen.script,
            voiceFileName: fileName,
            backgroundRaw: bgRaw
        )

        modelContext.insert(session)
    }
}
