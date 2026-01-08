//
//  BreathingLog.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 06.01.2026.
//

import SwiftData
import Foundation

@Model
final class BreathingLog {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var durationSeconds: Int

    /// Храним стабильный ID (rawValue) — не локализованный текст!
    var moodRaw: String

    init(durationSeconds: Int, mood: BreathingMood) {
        self.id = UUID()
        self.createdAt = .now
        self.durationSeconds = durationSeconds
        self.moodRaw = mood.rawValue
    }

    /// Если где-то ещё создаёшь лог из String — оставь второй init
    init(durationSeconds: Int, moodRaw: String) {
        self.id = UUID()
        self.createdAt = .now
        self.durationSeconds = durationSeconds
        self.moodRaw = moodRaw
    }

    /// Возвращаем enum обратно. Если значение неизвестно — дефолт.
    var mood: BreathingMood {
        get { BreathingMood(rawValue: moodRaw) ?? .calm }
        set { moodRaw = newValue.rawValue }
    }

    /// Удобно для UI (локализованный текст)
    var moodTitle: String { mood.localizedTitleString }
}
