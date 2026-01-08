//
//  BreathingPhase.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 29.12.2025.
//

import Foundation
import SwiftUI

enum BreathingPhase: CaseIterable {
    case inhale
    case hold
    case exhale

    // Ключи для UI (дальше выводишь через Text(key) или L10n.s(key, lang:))
    var titleKey: String {
        switch self {
        case .inhale: return "bre_phase_inhale"
        case .hold:   return "bre_phase_hold"
        case .exhale: return "bre_phase_exhale"
        }
    }

    var instructionKey: String {
        switch self {
        case .inhale: return "bre_hint_inhale"
        case .hold:   return "bre_hint_hold"
        case .exhale: return "bre_hint_exhale"
        }
    }
}

struct BreathingPattern {
    let inhale: Int
    let hold: Int
    let exhale: Int

    var totalCycle: Int { inhale + hold + exhale }

    static func forMood(_ mood: BreathingMood) -> BreathingPattern {
        switch mood {
        case .calm:
            return .init(inhale: 4, hold: 4, exhale: 6)
        case .neutral:
            return .init(inhale: 4, hold: 4, exhale: 4)
        case .stressed:
            return .init(inhale: 4, hold: 6, exhale: 8)
        case .anxious:
            return .init(inhale: 3, hold: 6, exhale: 8)
        }
    }
}

enum BreathingDuration: Int, CaseIterable, Equatable {
    case one = 1
    case five = 5
    case ten = 10

    var seconds: Int { rawValue * 60 }

    func title(lang: AppLanguage) -> String {
        L10n.f("bre_duration_minutes_format", lang: lang, rawValue)
    }
}
