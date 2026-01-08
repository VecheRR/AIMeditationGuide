//
//  Analytics.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 07.01.2026.
//


import Foundation
import YandexMobileMetrica

enum Analytics {

    /// Универсальная отправка событий
    static func event(_ name: String, _ params: [String: Any]? = nil) {
        YMMYandexMetrica.reportEvent(name, parameters: params) { error in
            #if DEBUG
            print("📊 AppMetrica error:", error)
            #endif
        }
    }

    /// Трекинг экранов
    static func screen(_ name: String) {
        event("screen_view", ["screen": name])
    }
}
