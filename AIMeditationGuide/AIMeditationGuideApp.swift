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
import FirebaseCore
import AppsFlyerLib

import AppTrackingTransparency
import AdSupport

@main
struct AIMeditationGuideApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(AppModelContainer.container)
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, UIApplicationDelegate, AppsFlyerLibDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        // 1) Apphud
        if Keys.apphud.isEmpty {
            assertionFailure("APPHUD_API_KEY is missing in Info.plist")
        } else {
            Apphud.start(apiKey: Keys.apphud)
        }

        // 2) AppMetrica
        if Keys.appmetrica.isEmpty {
            assertionFailure("APPMETRICA_API_KEY is missing in Info.plist")
        } else if let config = YMMYandexMetricaConfiguration(apiKey: Keys.appmetrica) {
            config.handleFirstActivationAsUpdate = false
            YMMYandexMetrica.activate(with: config)
        }

        // 3) Firebase
        FirebaseApp.configure()

        // 4) AdMob
        MobileAds.shared.start()

        // 5) AppsFlyer
        configureAppsFlyer()

        // 6) ATT (даём AppsFlyer подождать)
        configureATTFlow()

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // стандартная рекомендация AppsFlyer
        AppsFlyerLib.shared().start()
    }

    // MARK: - AppsFlyer

    private func configureAppsFlyer() {
        // IMPORTANT: добавь это в Info.plist и в Keys.swift (если ещё нет)
        // APPSFLYER_APP_ID = "123456789" (без id)
        let devKey = Keys.appsflyer
        let appId  = Keys.plist("APPSFLYER_APP_ID")

        if devKey.isEmpty { assertionFailure("APPSFLYER_DEV_KEY is missing in Info.plist") }
        if appId.isEmpty  { assertionFailure("APPSFLYER_APP_ID is missing in Info.plist") }

        let af = AppsFlyerLib.shared()
        af.appsFlyerDevKey = devKey
        af.appleAppID = appId
        af.delegate = self

        #if DEBUG
        af.isDebug = true
        #endif
    }

    // MARK: - ATT

    private func configureATTFlow() {
        guard #available(iOS 14, *) else { return }

        // пусть ждёт ATT (но не вечно)
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)

        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            ATTrackingManager.requestTrackingAuthorization { _ in
                // безопасно дернуть start ещё раз
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                }
            }
        }
    }

    // MARK: - AppsFlyerLibDelegate -> Apphud attribution

    func onConversionDataSuccess(_ conversionInfo: [AnyHashable: Any]) {
        let uid = AppsFlyerLib.shared().getAppsFlyerUID()

        // ВАЖНО: без trailing closure — иначе "Extra trailing closure passed in call"
        Apphud.setAttribution(
            data: ApphudAttributionData(rawData: conversionInfo),
            from: .appsFlyer,
            identifer: uid,
            callback: nil
        )
    }

    func onConversionDataFail(_ error: Error) {
        let uid = AppsFlyerLib.shared().getAppsFlyerUID()

        // тоже передаем как rawData, чтобы тип совпадал
        Apphud.setAttribution(
            data: ApphudAttributionData(rawData: ["error": error.localizedDescription]),
            from: .appsFlyer,
            identifer: uid,
            callback: nil
        )
    }
}
