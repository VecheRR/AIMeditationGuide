//
//  BreathingMood.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 06.01.2026.
//

import SwiftUI

enum BreathingMood: String, CaseIterable, Equatable {
    case calm, neutral, stressed, anxious

    func title(lang: AppLanguage) -> String {
        L10n.s("bre_mood_\(rawValue)", lang: lang)
    }

    var localizedTitleString: String {
        // если где-то нужен String без lang — можно оставить так:
        NSLocalizedString("bre_mood_\(rawValue)", comment: "")
    }
}
