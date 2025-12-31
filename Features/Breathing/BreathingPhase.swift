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

    var titleKey: LocalizedStringKey {
        switch self {
        case .inhale: return "bre_phase_inhale"
        case .hold:   return "bre_phase_hold"
        case .exhale: return "bre_phase_exhale"
        }
    }

    var instructionKey: LocalizedStringKey {
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
        case .calm:    return .init(inhale: 4, hold: 4, exhale: 6)
        case .neutral: return .init(inhale: 4, hold: 4, exhale: 4)
        case .stressed:return .init(inhale: 4, hold: 6, exhale: 8)
        case .anxious: return .init(inhale: 3, hold: 6, exhale: 8)
        }
    }
}

enum BreathingMood: CaseIterable, Equatable {
    case calm
    case neutral
    case stressed
    case anxious

    var titleKey: LocalizedStringKey {
        switch self {
        case .calm:     return "bre_mood_calm"
        case .neutral:  return "bre_mood_neutral"
        case .stressed: return "bre_mood_stressed"
        case .anxious:  return "bre_mood_anxious"
        }
    }

    /// Для сохранения в историю как ТЕКСТ (уже локализованный)
    var localizedTitleString: String {
        NSLocalizedString(keyString, comment: "")
    }

    private var keyString: String {
        switch self {
        case .calm:     return "bre_mood_calm"
        case .neutral:  return "bre_mood_neutral"
        case .stressed: return "bre_mood_stressed"
        case .anxious:  return "bre_mood_anxious"
        }
    }
}

enum BreathingDuration: Int, CaseIterable, Equatable {
    case one = 1
    case five = 5
    case ten = 10

    var seconds: Int { rawValue * 60 }

    /// "1 min" / "5 min" через Localizable: bre_duration_minutes = "%d min";
    var title: String {
        let format = NSLocalizedString("bre_duration_minutes", comment: "")
        return String(format: format, rawValue)
    }
}
