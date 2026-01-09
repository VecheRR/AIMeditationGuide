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
            goals: ["calm focus", "stress relief"], // это internal goals; язык будет учитываться ниже в prompts
            recentPractices: []
        )
    }
}

struct RoutineGeneratorService {
    private let client = OpenAIClient()

    /// Generates 1–3 purposeful practices using the OpenAI client.
    func generateRoutine(
        context: RoutineGenerationContext? = nil,
        lang: AppLanguage
    ) async throws -> [RoutineItem] {

        let ctx = context ?? RoutineGenerationContext.basic()

        let dayPart = DayPart(date: ctx.referenceDate)

        let system = systemPrompt(lang: lang)
        let user = userPrompt(context: ctx, dayPart: dayPart, lang: lang)

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
            // НЕ локализуем здесь через NSLocalizedDescription, потому что ты уже перешёл на errorKey в VM
            // Пусть VM покажет L10n.s("routine_error_empty_ai_response", ...)
            throw RoutineGeneratorError.emptyAIResponse
        }

        return Array(mapped)
    }

    // MARK: - Prompts

    private func systemPrompt(lang: AppLanguage) -> String {
        // Системный промпт проще держать ключами, чтобы у тебя не было англ внутри кода.
        // Но тут важно: L10n.s требует lang -> он у нас есть.
        let languageHint: String = {
            switch lang {
            case .ru: return L10n.s("routine_ai_language_ru", lang: lang)
            case .en: return L10n.s("routine_ai_language_en", lang: lang)
            case .system:
                // system = как Locale пользователя; но в L10n у тебя system уже выбирает нужный файл.
                // Для подсказки модели лучше явно: English by default.
                return L10n.s("routine_ai_language_system", lang: lang)
            }
        }()

        return """
        \(L10n.s("routine_ai_system_line1", lang: lang))
        \(L10n.s("routine_ai_system_line2", lang: lang))
        \(L10n.s("routine_ai_system_line3", lang: lang))
        \(L10n.s("routine_ai_system_line4", lang: lang))
        \(languageHint)
        """
    }

    private func userPrompt(context: RoutineGenerationContext, dayPart: DayPart, lang: AppLanguage) -> String {
        let historyText: String = {
            if context.recentPractices.isEmpty {
                return L10n.s("routine_ai_history_empty", lang: lang)
            } else {
                let joined = context.recentPractices.prefix(6).map { item in
                    let completed = item.completed
                        ? L10n.s("routine_ai_yes", lang: lang)
                        : L10n.s("routine_ai_no", lang: lang)

                    // "- Title (10m) completed: yes"
                    return String(
                        format: L10n.s("routine_ai_history_line_format", lang: lang),
                        item.title,
                        item.durationMinutes,
                        completed
                    )
                }.joined(separator: "\n")

                return String(
                    format: L10n.s("routine_ai_history_block_format", lang: lang),
                    joined
                )
            }
        }()

        let goalsText: String = {
            if context.goals.isEmpty {
                return L10n.s("routine_ai_goals_fallback", lang: lang)
            } else {
                // goals — internal keywords, но их можно показать как есть, а можно подсунуть “перевод”
                // Если хочешь красиво — храни goals как IDs, но пока оставим.
                let joined = context.goals.joined(separator: ", ")
                return String(
                    format: L10n.s("routine_ai_goals_format", lang: lang),
                    joined
                )
            }
        }()

        // dayPart локализуем, чтобы модель отвечала на нужном языке + “утро/вечер”
        let dayPartText = dayPart.localizedTitle(lang: lang)

        return """
        \(String(format: L10n.s("routine_ai_time_of_day_format", lang: lang), dayPartText))
        \(goalsText)
        \(historyText)

        \(L10n.s("routine_ai_user_request", lang: lang))
        """
    }
}

enum RoutineGeneratorError: Error {
    case emptyAIResponse
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

    func localizedTitle(lang: AppLanguage) -> String {
        switch self {
        case .morning:   return L10n.s("routine_daypart_morning", lang: lang)
        case .afternoon: return L10n.s("routine_daypart_afternoon", lang: lang)
        case .evening:   return L10n.s("routine_daypart_evening", lang: lang)
        }
    }
}
