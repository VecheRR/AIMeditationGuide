//
//  GeneratorViewModel.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import Foundation
import Combine

@MainActor
final class GeneratorViewModel: ObservableObject {
    @Published var goal: GenGoal? = nil
    @Published var duration: GenDuration? = nil
    @Published var voice: GenVoice? = nil
    @Published var background: GenBackground? = nil

    @Published var isLoading = false
    @Published var errorText: String?
    @Published var generated: MeditationAIResponse?
    @Published var coverImageURL: URL?

    private let tts = OpenAITTSClient()
    @Published var voiceFileURL: URL?
    
    private let client = OpenAIClient()

    var canGenerate: Bool {
        goal != nil && duration != nil && voice != nil && background != nil
    }

    func generate() async {
        guard let goal, let duration, let voice, let background else { return }
        errorText = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let res = try await client.generateMeditation(
                goal: goal.rawValue,
                durationMin: duration.rawValue,
                voiceStyle: voice.rawValue
            )
            generated = res

            // Try to create a matching cover while we synthesize the voice
            coverImageURL = try? await client.generateMeditationCover(
                goal: goal.rawValue,
                durationMin: duration.rawValue,
                voiceStyle: voice.rawValue,
                background: background.rawValue
            )

            // Текст для озвучки — используем script
            self.voiceFileURL = nil
            let voiceURL = try await tts.synthesizeToFile(text: res.script)
            self.voiceFileURL = voiceURL
        } catch {
            errorText = error.localizedDescription
        }
    }
}
