//
//  Analytics.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 07.01.2026.
//


import Foundation
import YandexMobileMetrica

enum Analytics {
    static func screen(_ name: String) {
        AnalyticsService.shared.screen(name)
    }

    static func event(_ name: String, _ params: [String: Any] = [:]) {
        AnalyticsService.shared.log(name, params)
    }
}
