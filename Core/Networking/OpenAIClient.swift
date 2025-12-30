//
//  OpenAIClient.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import Foundation

struct MeditationAIResponse: Decodable {
    let title: String
    let summary: String
    let script: String
}

struct GeneratedImageResponse: Decodable {
    struct DataItem: Decodable { let url: String }
    let data: [DataItem]
}

final class OpenAIClient {
    private let apiKey: String
    private let model: String

    init(apiKey: String = AppConfig.openAIKey,
         model: String = AppConfig.openAIModel) {
        self.apiKey = apiKey
        self.model = model
    }

    func chatJSON<T: Decodable>(system: String, user: String, temperature: Double = 0.3) async throws -> T {
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ],
            "response_format": ["type": "json_object"],
            "temperature": temperature
        ]

        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAI", code: 1, userInfo: [NSLocalizedDescriptionKey: text])
        }

        struct Root: Decodable {
            struct Choice: Decodable {
                struct Msg: Decodable { let content: String }
                let message: Msg
            }
            let choices: [Choice]
        }

        let root = try JSONDecoder().decode(Root.self, from: data)
        let content = root.choices.first?.message.content ?? ""

        if let jsonData = content.data(using: .utf8) {
            do {
                return try JSONDecoder().decode(T.self, from: jsonData)
            } catch {
                if let start = content.firstIndex(of: "{"),
                   let end = content.lastIndex(of: "}") {
                    let sliced = String(content[start...end])
                    let slicedData = Data(sliced.utf8)
                    return try JSONDecoder().decode(T.self, from: slicedData)
                }
                throw NSError(
                    domain: "OpenAI.Decode",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to decode response. Content:\n\(content)\nError: \(error)"]
                )
            }
        }

        throw NSError(domain: "OpenAI.Decode", code: 3, userInfo: [NSLocalizedDescriptionKey: "Empty content"])
    }

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

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.2
        ]

        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAI", code: 1, userInfo: [NSLocalizedDescriptionKey: text])
        }

        // парсим стандартный ответ chat.completions
        struct Root: Decodable {
            struct Choice: Decodable {
                struct Msg: Decodable { let content: String }
                let message: Msg
            }
            let choices: [Choice]
        }

        let root = try JSONDecoder().decode(Root.self, from: data)
        let content = root.choices.first?.message.content ?? ""

        print("OPENAI CONTENT:\n\(content)\n---")

        // 1) пробуем как есть
        if let jsonData = content.data(using: .utf8) {
            do {
                return try JSONDecoder().decode(MeditationAIResponse.self, from: jsonData)
            } catch {
                // 2) fallback: вырезаем JSON между первой { и последней }
                if let start = content.firstIndex(of: "{"),
                   let end = content.lastIndex(of: "}") {
                    let sliced = String(content[start...end])
                    print("SLICED JSON:\n\(sliced)\n---")
                    let slicedData = Data(sliced.utf8)
                    return try JSONDecoder().decode(MeditationAIResponse.self, from: slicedData)
                }
                // 3) если совсем не получилось — покажем текст ошибки с контентом
                throw NSError(
                    domain: "OpenAI.Decode",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to decode MeditationAIResponse. Content:\n\(content)\nError: \(error)"]
                )
            }
        }

        throw NSError(domain: "OpenAI.Decode", code: 3, userInfo: [NSLocalizedDescriptionKey: "Empty content"])
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

        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/images/generations")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAI.Image", code: 4, userInfo: [NSLocalizedDescriptionKey: text])
        }

        let root = try JSONDecoder().decode(GeneratedImageResponse.self, from: data)
        if let urlString = root.data.first?.url {
            return URL(string: urlString)
        }

        return nil
    }
}
