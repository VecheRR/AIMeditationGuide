//
//  AppConfig.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import Foundation

enum AppConfig {
    static var openAIKey: String { info("OPENAI_API_KEY") }
    static var openAIModel: String { info("OPENAI_MODEL") }
    static var openAITTSModel: String { info("OPENAI_TTS_MODEL") }
    static var openAITTSVoice: String { info("OPENAI_TTS_VOICE") }

    private static func info(_ key: String) -> String {
        guard let v = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !v.contains("$(") // если не подставилось из xcconfig
        else {
            fatalError("Missing Info.plist key: \(key). Check xcconfig + Info.plist.")
        }
        return v
    }
}
