//
//  GeneratorModels.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import Foundation

enum GenGoal: String, CaseIterable, Identifiable {
    case reduceStress = "Reduce stress"
    case improveSleep = "Improve sleep"
    case increaseFocus = "Increase focus"
    case boostEnergy = "Boost energy"
    case calmAnxiety = "Calm anxiety"
    var id: String { rawValue }
}

enum GenDuration: Int, CaseIterable, Identifiable {
    case min5 = 5, min10 = 10, min15 = 15
    var id: Int { rawValue }
    var title: String { "\(rawValue) min" }
}

enum GenVoice: String, CaseIterable, Identifiable {
    case soft = "Soft"
    case neutral = "Neutral"
    case deep = "Deep"
    var id: String { rawValue }
}

enum GenBackground: String, CaseIterable, Identifiable {
    case nature = "Nature"
    case ambient = "Waves"
    case rain = "Rain"
    case none = "None"
    var id: String { rawValue }
}
