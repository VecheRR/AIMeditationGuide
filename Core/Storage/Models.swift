//
//  Models.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import Foundation
import SwiftData

@Model
final class MeditationSession {
    var createdAt: Date
    var durationMinutes: Int
    var title: String
    var summary: String
    var script: String

    // NEW
    var voiceFileName: String?
    var backgroundRaw: String

    init(durationMinutes: Int, title: String, summary: String, script: String,
         voiceFileName: String?, backgroundRaw: String, createdAt: Date = Date()) {
        self.durationMinutes = durationMinutes
        self.title = title
        self.summary = summary
        self.script = script
        self.voiceFileName = voiceFileName
        self.backgroundRaw = backgroundRaw
        self.createdAt = createdAt
    }
}

extension MeditationSession {
    var background: GenBackground {
        GenBackground(rawValue: backgroundRaw) ?? .none
    }

    var voiceURL: URL? {
        guard let name = voiceFileName else { return nil }
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(name)
    }
}

@Model
final class BreathingLog {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var durationSeconds: Int
    var mood: String

    init(durationSeconds: Int, mood: String) {
        self.id = UUID()
        self.createdAt = .now
        self.durationSeconds = durationSeconds
        self.mood = mood
    }
}

@Model
final class RoutinePlan {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var itemsJSON: String
    var isSaved: Bool

    init(itemsJSON: String, isSaved: Bool = false) {
        self.id = UUID()
        self.createdAt = .now
        self.itemsJSON = itemsJSON
        self.isSaved = isSaved
    }
}
