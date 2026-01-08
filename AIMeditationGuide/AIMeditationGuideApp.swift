//
//  AIMeditationGuideApp.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 29.12.2025.
//

import SwiftUI
import SwiftData
import ApphudSDK
import YandexMobileMetrica
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport

@main
struct AIMeditationGuideApp: App {

    // Инициализация SDK на старте приложения
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(AppModelContainer.container)
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, UIApplicationDelegate {
    private enum Keys {
        static var apphud: String {
            (Bundle.main.object(forInfoDictionaryKey: "APPHUD_API_KEY") as? String ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        static var appmetrica: String {
            (Bundle.main.object(forInfoDictionaryKey: "APPMETRICA_API_KEY") as? String ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        static var admobAppId: String {
            (Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // 1) Apphud
        let apphudKey = Keys.apphud
        if !apphudKey.isEmpty {
            Apphud.start(apiKey: apphudKey)
        } else {
            assertionFailure("APPHUD_API_KEY is missing in Info.plist")
        }

        // 2) AppMetrica
        let metricaKey = Keys.appmetrica
        if !metricaKey.isEmpty, let config = YMMYandexMetricaConfiguration(apiKey: metricaKey) {
            config.handleFirstActivationAsUpdate = false
            YMMYandexMetrica.activate(with: config)
        } else {
            assertionFailure("APPMETRICA_API_KEY is missing in Info.plist")
        }

        // 3) AdMob init
        // ВАЖНО: в Info.plist должен быть GADApplicationIdentifier = ca-app-pub-xxx~yyy
        let admobId = Keys.admobAppId
        if admobId.isEmpty {
            assertionFailure("GADApplicationIdentifier is missing in Info.plist")
        }
        MobileAds.shared.start()

        // 4) ATT (по желанию, но лучше для рекламы)
        requestATTIfNeeded()

        return true
    }

    private func requestATTIfNeeded() {
        guard #available(iOS 14, *) else { return }
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}
