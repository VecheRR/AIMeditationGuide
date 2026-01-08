//
//  IronSourceManager.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 07.01.2026.
//

import UIKit
import IronSource

@MainActor
final class AdsManager: NSObject {

    static let shared = AdsManager()

    private let appKey = "YOUR_APP_KEY"
    private let interstitialAdUnitId = "YOUR_INTERSTITIAL_AD_UNIT_ID"

    private var interstitial: LPMInterstitialAd?

    private override init() {
        super.init()
        initIronSource()
    }

    private func initIronSource() {
        let request = LPMInitRequestBuilder(appKey: appKey).build()

        LevelPlay.initWith(request) { [weak self] _, error in
            if let error = error {
                print("❌ IronSource init error:", error.localizedDescription)
                return
            }

            print("✅ IronSource initialized")

            self?.setupInterstitial()
        }
    }

    private func setupInterstitial() {
        let ad = LPMInterstitialAd(adUnitId: interstitialAdUnitId)
        ad.setDelegate(self)
        self.interstitial = ad
        ad.loadAd()
    }

    // ===== PUBLIC API (как раньше) =====

    func showInterstitial() {
        guard
            let vc = topViewController(),
            let interstitial
        else { return }

        interstitial.showAd(viewController: vc)
    }
}
