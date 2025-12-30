//
//  RoutineGeneratorService.swift
//  AIMeditationGuide
//
//  Created by OpenAI ChatGPT.
//

import Foundation

struct RoutineGeneratorService {
    /// Pseudo-AI generator that adapts to the time of day and ensures 1–3 purposeful practices.
    func generateRoutine(referenceDate: Date = .now) async throws -> [RoutineItem] {
        try await Task.sleep(nanoseconds: 300_000_000) // Simulate latency

        let dayPart = DayPart(date: referenceDate)

        var practices: [RoutineItem] = []

        if dayPart == .morning {
            practices.append(
                RoutineItem(
                    title: "Morning meditation",
                    details: "7 minutes of gentle breath awareness to set intention for the day.",
                    durationMinutes: 7
                )
            )
        }

        practices.append(
            RoutineItem(
                title: "Afternoon breathing",
                details: "3 rounds of box breathing to reset focus and calm stress mid-day.",
                durationMinutes: 5
            )
        )

        if dayPart != .morning {
            practices.append(
                RoutineItem(
                    title: "Evening relaxation",
                    details: "10-minute body scan with soft background sound to ease into rest.",
                    durationMinutes: 10
                )
            )
        }

        if dayPart == .evening {
            practices.append(
                RoutineItem(
                    title: "Gratitude check-in",
                    details: "Write down three things that went well today before heading to bed.",
                    durationMinutes: 5
                )
            )
        }

        // Always return between 1 and 3 key practices for the day
        let prioritized = practices.prefix(3)
        return Array(prioritized)
    }
}

private enum DayPart {
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
