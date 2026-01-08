//
//  AnalyticsService.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 08.01.2026.
//

import Foundation
import FirebaseAnalytics
import YandexMobileMetrica
import AppsFlyerLib


final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    func log(_ name: String, _ params: [String: Any] = [:]) {
        // Firebase
        FirebaseAnalytics.Analytics.logEvent(name, parameters: params.isEmpty ? nil : params)

        // AppMetrica
        if params.isEmpty {
            YMMYandexMetrica.reportEvent(name, onFailure: nil)
        } else {
            YMMYandexMetrica.reportEvent(name, parameters: params, onFailure: nil)
        }

        // AppsFlyer
        AppsFlyerLib.shared().logEvent(name, withValues: params)
    }

    func screen(_ name: String) {
        log("screen_open", ["screen": name])
    }
}
