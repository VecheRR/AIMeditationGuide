//
//  GeneratorModels.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import Foundation

enum GenGoal: String, CaseIterable, Identifiable {
    case reduce_stress
    case improve_sleep
    case increase_focus
    case boost_energy
    case calm_anxiety
    var id: String { rawValue }
}

enum GenVoice: String, CaseIterable, Identifiable {
    case soft = "soft"
    case neutral = "neutral"
    case deep = "deep"
    var id: String { rawValue }
}

enum GenBackground: String, CaseIterable, Identifiable {
    case nature = "nature"
    case ambient = "ambient"
    case rain = "rain"
    case none = "none"
    var id: String { rawValue }

    static func from(raw: String) -> GenBackground {
        // поддержка легаси значений
        if raw == "Waves" || raw == "Ambient music" { return .ambient }
        if raw == "Nature" { return .nature }
        if raw == "Rain" { return .rain }
        if raw == "None" { return .none }
        return GenBackground(rawValue: raw) ?? .none
    }
}

enum GenDuration: Int, CaseIterable, Identifiable {
    case min5 = 5
    case min10 = 10
    case min15 = 15

    var id: Int { rawValue }

    var title: String {
        // либо отдельные ключи gen_duration_5, gen_duration_10...
        String(localized: "gen_duration_\(rawValue)")
    }
}

