//
//  AppModelContainer.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftData

enum AppModelContainer {
    static let container: ModelContainer = {
        do {
            let schema = Schema([
                MeditationSession.self,
                BreathingLog.self,
                RoutinePlan.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
