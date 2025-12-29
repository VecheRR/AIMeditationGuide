//
//  OpenAITTSClient.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import Foundation

final class OpenAITTSClient {
    private let apiKey: String
    private let model: String
    private let voice: String

    init(apiKey: String = AppConfig.openAIKey,
         model: String = AppConfig.openAITTSModel,
         voice: String = AppConfig.openAITTSVoice) {
        self.apiKey = apiKey
        self.model = model
        self.voice = voice
    }

    /// Returns local file URL to saved mp3.
    func synthesizeToFile(text: String) async throws -> URL {
        let url = URL(string: "https://api.openai.com/v1/audio/speech")!

        let body: [String: Any] = [
            "model": model,
            "voice": voice,
            "format": "mp3",
            "input": text
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAI.TTS", code: 1, userInfo: [NSLocalizedDescriptionKey: text])
        }

        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("tts-\(UUID().uuidString).mp3")

        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}
