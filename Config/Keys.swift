//
//  Keys.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 07.01.2026.
//

import Foundation

enum Keys {
    static var apphud: String { plist("APPHUD_API_KEY") }
    static var appmetrica: String { plist("APPMETRICA_API_KEY") }
    static var rewardedAd: String { plist("ADMOB_REWARDED_AD_UNIT_ID") }
    static var appsflyer: String { plist("APPSFLYER_DEV_KEY") }
    static var appsflyerAppId: String { plist("APPLE_APP_ID") }
    static func plist(_ key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
