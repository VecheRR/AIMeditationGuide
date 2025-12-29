//
//  RoutineGeneratorService.swift
//  AIMeditationGuide
//
//  Created by OpenAI ChatGPT.
//

import Foundation

/// Stub generator to produce a simple set of daily practices.
/// In the future this can be replaced with an AI-powered routine builder.
struct RoutineGeneratorService {
    func generateRoutine() async throws -> [RoutineItem] {
        try await Task.sleep(nanoseconds: 300_000_000) // Simulate latency

        let practices: [RoutineItem] = [
            RoutineItem(title: "Grounding Breath", details: "5 minutes of calm nasal breathing to center attention.", durationMinutes: 5),
            RoutineItem(title: "Body Scan", details: "Release tension scanning from head to toes with gentle attention.", durationMinutes: 8),
            RoutineItem(title: "Loving-Kindness", details: "Repeat compassionate phrases toward yourself and others.", durationMinutes: 7),
            RoutineItem(title: "Gratitude Journal", details: "Write down three things you appreciate right now.", durationMinutes: 5)
        ]

        return practices
    }
}
