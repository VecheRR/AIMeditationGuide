//
//  BreathingPhase.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 29.12.2025.
//

import Foundation

enum BreathingPhase: String {
    case inhale = "Inhale"
    case hold = "Hold"
    case exhale = "Exhale"
}

struct BreathingPattern {
    let inhale: Int
    let hold: Int
    let exhale: Int

    var totalCycle: Int {
        inhale + hold + exhale
    }

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

enum BreathingMood: String, CaseIterable {
    case calm = "Calm"
    case neutral = "Neutral"
    case stressed = "Stressed"
    case anxious = "Anxious"
}

enum BreathingDuration: Int, CaseIterable {
    case one = 1
    case five = 5
    case ten = 10

    var seconds: Int {
        rawValue * 60
    }
}
