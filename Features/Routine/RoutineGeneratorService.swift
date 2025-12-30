//
//  RoutineGeneratorService.swift
//  AIMeditationGuide
//
//  Created by OpenAI ChatGPT.
//

import Foundation

struct RoutineGenerationContext {
    struct RecentPractice: Codable {
        let title: String
        let completed: Bool
        let durationMinutes: Int
    }

    var referenceDate: Date
    var goals: [String]
    var recentPractices: [RecentPractice]

    static func basic(referenceDate: Date = .now) -> RoutineGenerationContext {
        RoutineGenerationContext(
            referenceDate: referenceDate,
            goals: ["calm focus", "stress relief"],
            recentPractices: []
        )
    }
}

struct RoutineGeneratorService {
    private let client = OpenAIClient()

    /// Generates 1–3 purposeful practices using the OpenAI client.
    func generateRoutine(context: RoutineGenerationContext = .basic()) async throws -> [RoutineItem] {
        let dayPart = DayPart(date: context.referenceDate)

        let system = """
        You are a mindful routine coach. Reply ONLY with JSON using shape:
        {"items":[{"title":"string","details":"string","durationMinutes":integer}]}
        Provide 1 to 3 concise, actionable practices (3–20 minutes each). Avoid markdown.
        """

        let historyText: String
        if context.recentPractices.isEmpty {
            historyText = "No recent practices logged."
        } else {
            let joined = context.recentPractices.prefix(6).map { item in
                "- \(item.title) (\(item.durationMinutes)m) completed: \(item.completed ? "yes" : "no")"
            }.joined(separator: "\n")
            historyText = "Recent practice history:\n\(joined)"
        }

        let goalsText = context.goals.isEmpty ? "Goal: general calm and focus." : "Goals: \(context.goals.joined(separator: ", "))."

        let user = """
        Time of day: \(dayPart.rawValue).
        \(goalsText)
        \(historyText)

        Suggest next mindful practices tailored to the time of day. Include short instructions in details and realistic durations.
        """

        struct RoutineAIResponse: Decodable { let items: [RoutineAIItem] }
        struct RoutineAIItem: Decodable { let title: String; let details: String; let durationMinutes: Int }

        let response: RoutineAIResponse = try await client.chatJSON(system: system, user: user, temperature: 0.4)
        let mapped = response.items.prefix(3).compactMap { item -> RoutineItem? in
            guard !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !item.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            let duration = max(1, min(item.durationMinutes, 60))
            return RoutineItem(title: item.title, details: item.details, durationMinutes: duration)
        }

        guard !mapped.isEmpty else {
            throw NSError(domain: "RoutineGenerator", code: 0, userInfo: [NSLocalizedDescriptionKey: "AI returned no practices"])
        }

        return Array(mapped)
    }
}

private enum DayPart: String {
    case morning, afternoon, evening

    init(date: Date) {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: self = .morning
        case 12..<18: self = .afternoon
        default: self = .evening
        }
    }
}
