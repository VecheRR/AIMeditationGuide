//
//  OpenAIClient.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 29.12.2025.
//

import Foundation

// MARK: - App models

struct MeditationAIResponse: Decodable {
    let title: String
    let summary: String
    let script: String
}

struct GeneratedImageResponse: Decodable {
    struct DataItem: Decodable { let url: String }
    let data: [DataItem]
}

// MARK: - OpenAI API response models (MUST be top-level)

struct OpenAIChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable { let content: String }
        let message: Message
    }
    let choices: [Choice]
}

// MARK: - Client

final class OpenAIClient {
    private let apiKey: String
    private let model: String

    init(apiKey: String = AppConfig.openAIKey,
         model: String = AppConfig.openAIModel) {
        self.apiKey = apiKey
        self.model = model
    }

    // Универсальная штука: просим модель вернуть JSON и декодим в T
    func chatJSON<T: Decodable>(
        system: String,
        user: String,
        temperature: Double = 0.3
    ) async throws -> T {

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ],
            "response_format": ["type": "json_object"],
            "temperature": temperature
        ]

        let data = try await postJSON(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            body: body,
            domain: "OpenAI.Chat"
        )

        let root = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        let content = root.choices.first?.message.content ?? ""

        return try decodeJSONFromContent(T.self, content: content)
    }

    // Медитация — теперь просто через chatJSON (никакого дублирования)
    func generateMeditation(goal: String, durationMin: Int, voiceStyle: String) async throws -> MeditationAIResponse {
        let system = """
        You are an expert meditation coach.
        Return ONLY valid JSON with keys: title, summary, script.
        No markdown, no extra text.
        The script must match the requested duration.
        """

        let user = """
        Goal: \(goal)
        Duration: \(durationMin) minutes
        Voice style: \(voiceStyle)

        Create a guided meditation with structure:
        1) greeting + intention
        2) breathing
        3) body scan
        4) visualization
        5) gentle closing
        """

        return try await chatJSON(system: system, user: user, temperature: 0.2)
    }

    func generateMeditationCover(goal: String, durationMin: Int, voiceStyle: String, background: String) async throws -> URL? {
        let prompt = """
        Calming, cinematic illustration for a guided meditation cover.
        Goal: \(goal).
        Duration: \(durationMin) minutes.
        Voice: \(voiceStyle) tone.
        Background sound vibe: \(background).
        Soft gradients, soothing nature elements, no text, high resolution.
        """

        let body: [String: Any] = [
            "model": "gpt-image-1",
            "prompt": prompt,
            "size": "1024x1024",
            "style": "vivid"
        ]

        let data = try await postJSON(
            url: URL(string: "https://api.openai.com/v1/images/generations")!,
            body: body,
            domain: "OpenAI.Image"
        )

        let root = try JSONDecoder().decode(GeneratedImageResponse.self, from: data)
        guard let urlString = root.data.first?.url else { return nil }
        return URL(string: urlString)
    }

    // MARK: - Networking helpers

    private func postJSON(url: URL, body: [String: Any], domain: String) async throws -> Data {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        print("OPENAI key len=\(trimmed.count) prefix=\(trimmed.prefix(7)) suffix=\(trimmed.suffix(4)) model=\(model)")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)

        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: domain, code: 1, userInfo: [NSLocalizedDescriptionKey: text])
        }
    
        return data
    }

    // MARK: - Decoding helpers

    private func decodeJSONFromContent<T: Decodable>(_ type: T.Type, content: String) throws -> T {
        // 1) пробуем декодить как есть
        if let jsonData = content.data(using: .utf8) {
            if let decoded = try? JSONDecoder().decode(T.self, from: jsonData) {
                return decoded
            }
        }

        // 2) fallback: вырезаем JSON между первой { и последней }
        if let start = content.firstIndex(of: "{"),
           let end = content.lastIndex(of: "}") {
            let sliced = String(content[start...end])
            let slicedData = Data(sliced.utf8)

            do {
                return try JSONDecoder().decode(T.self, from: slicedData)
            } catch {
                throw NSError(
                    domain: "OpenAI.Decode",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to decode JSON. Content:\n\(content)\nError: \(error)"]
                )
            }
        }

        throw NSError(
            domain: "OpenAI.Decode",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Model returned empty or non-JSON content:\n\(content)"]
        )
    }
}
