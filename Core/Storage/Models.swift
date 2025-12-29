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
    var voiceFilePath: String?
    var backgroundRaw: String
    var backgroundFilePath: String?

    init(durationMinutes: Int, title: String, summary: String, script: String,
         voiceFileName: String?, voiceFilePath: String? = nil,
         backgroundRaw: String, backgroundFilePath: String? = nil,
         createdAt: Date = Date()) {
        self.durationMinutes = durationMinutes
        self.title = title
        self.summary = summary
        self.script = script
        self.voiceFileName = voiceFileName
        self.voiceFilePath = voiceFilePath
        self.backgroundRaw = backgroundRaw
        self.backgroundFilePath = backgroundFilePath
        self.createdAt = createdAt
    }
}

extension MeditationSession {
    var background: GenBackground {
        GenBackground(rawValue: backgroundRaw) ?? .none
    }

    var voiceURL: URL? {
        if let path = voiceFilePath {
            return URL(fileURLWithPath: path)
        }

        guard let name = voiceFileName else { return nil }
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(name)
    }

    var backgroundURL: URL? {
        guard let path = backgroundFilePath else { return nil }
        return URL(fileURLWithPath: path)
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
    var statusRaw: String = RoutineStatus.active.rawValue

    init(itemsJSON: String, isSaved: Bool = false, status: RoutineStatus = .active) {
        self.id = UUID()
        self.createdAt = .now
        self.itemsJSON = itemsJSON
        self.isSaved = isSaved
        self.statusRaw = status.rawValue
    }
}

extension RoutinePlan {
    var items: [RoutineItem] {
        get {
            guard let data = itemsJSON.data(using: .utf8),
                  let items = try? JSONDecoder().decode([RoutineItem].self, from: data) else {
                return []
            }
            return items
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                itemsJSON = json
            }
        }
    }

    var nextIncomplete: RoutineItem? {
        items.first(where: { !$0.isCompleted })
    }

    var status: RoutineStatus {
        get { RoutineStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }
}
