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
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(AppModelContainer.container)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    // 🔥 железобетон: просим ATT когда сцена стала active
                    AppDelegate.requestATTThenStartAppsFlyer()
                }
            }
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, UIApplicationDelegate, AppsFlyerLibDelegate {

    // делаем статиком, чтобы можно было дергать из scenePhase
    private static var didRequestATT: Bool {
        get { UserDefaults.standard.bool(forKey: "did_request_att") }
        set { UserDefaults.standard.set(newValue, forKey: "did_request_att") }
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        NSLog("✅ APP: didFinishLaunching")

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

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        NSLog("✅ APP: applicationDidBecomeActive")
        // Доп. страховка (не мешает сценам)
        Self.requestATTThenStartAppsFlyer()
    }

    // MARK: - AppsFlyer

    private func configureAppsFlyer() {
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

    // MARK: - ATT (железобетон)

    static func requestATTThenStartAppsFlyer() {
        #if targetEnvironment(simulator)
        NSLog("⚠️ ATT: SIMULATOR (может вести себя странно)")
        #endif

        guard #available(iOS 14, *) else {
            NSLog("ATT: iOS < 14 -> start AppsFlyer")
            AppsFlyerLib.shared().start()
            return
        }

        let status = ATTrackingManager.trackingAuthorizationStatus
        NSLog("ATT: status=%d didRequestATT=%@", status.rawValue, didRequestATT.description)

        // если уже не notDetermined — окна не будет
        guard status == .notDetermined else {
            NSLog("ATT: status != notDetermined -> start AppsFlyer")
            AppsFlyerLib.shared().start()
            return
        }

        // если уже пытались — не долбим
        guard !didRequestATT else {
            NSLog("ATT: already requested flag -> start AppsFlyer")
            AppsFlyerLib.shared().start()
            return
        }

        // AppsFlyer ждёт ATT
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)

        // важно: запрос только когда UI активен; даем небольшую паузу
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            NSLog("ATT: requesting now...")

            ATTrackingManager.requestTrackingAuthorization { newStatus in
                DispatchQueue.main.async {
                    didRequestATT = true
                    NSLog("ATT: result=%d", newStatus.rawValue)
                    AppsFlyerLib.shared().start()
                }
            }
        }
    }

    // MARK: - AppsFlyerLibDelegate -> Apphud attribution

    func onConversionDataSuccess(_ conversionInfo: [AnyHashable: Any]) {
        let uid = AppsFlyerLib.shared().getAppsFlyerUID()
        Apphud.setAttribution(
            data: ApphudAttributionData(rawData: conversionInfo),
            from: .appsFlyer,
            identifer: uid,
            callback: nil
        )
    }

    func onConversionDataFail(_ error: Error) {
        let uid = AppsFlyerLib.shared().getAppsFlyerUID()
        Apphud.setAttribution(
            data: ApphudAttributionData(rawData: ["error": error.localizedDescription]),
            from: .appsFlyer,
            identifer: uid,
            callback: nil
        )
    }
}
