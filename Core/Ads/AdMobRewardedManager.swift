//
//  AdMobRewardedManager.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 07.01.2026.
//

import Foundation
import GoogleMobileAds
import UIKit
import Combine

@MainActor
final class AdMobRewardedManager: NSObject, ObservableObject {

    static let shared = AdMobRewardedManager()

    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isReady: Bool = false

    private var rewardedAd: RewardedAd?

    private var adUnitId: String {
        Keys.rewardedAd.isEmpty
        ? "ca-app-pub-3940256099942544/5224354917" // test rewarded
        : Keys.rewardedAd
    }

    private var rewardEarned: Bool = false
    private var showContinuation: CheckedContinuation<Bool, Never>?

    // ✅ единая точка правды: реклама только для НЕ premium (включая debug premium)
    private var canShowAds: Bool {
        !ApphudManager.shared.premiumActive
    }

    // ✅ сброс состояния + безопасное завершение ожидания
    func disableAdsForPremium() {
        rewardedAd = nil
        isReady = false
        isLoading = false

        // если кто-то ждёт show() — премиуму “награду” можно отдать сразу
        showContinuation?.resume(returning: true)
        showContinuation = nil
    }

    func preload() {
        // ✅ Premium -> вообще не грузим
        guard canShowAds else {
            disableAdsForPremium()
            return
        }

        guard !isLoading else { return }

        isLoading = true
        isReady = false

        let request = Request()
        RewardedAd.load(with: adUnitId, request: request) { [weak self] ad, error in
            guard let self else { return }
            Task { @MainActor in
                // пока грузили — мог включиться premium (в т.ч. debug)
                guard self.canShowAds else {
                    self.disableAdsForPremium()
                    return
                }

                self.isLoading = false

                if let error {
                    print("AdMob Rewarded load error:", error)
                    self.rewardedAd = nil
                    self.isReady = false
                    return
                }

                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self
                self.isReady = true
                print("AdMob Rewarded loaded ✅")
            }
        }
    }

    /// true — только если получил награду.
    /// ✅ Premium: возвращаем true без рекламы.
    func show(from vc: UIViewController) async -> Bool {
        guard canShowAds else {
            disableAdsForPremium()
            return true
        }

        // если нет рекламы — попробуем подгрузить
        if rewardedAd == nil {
            preload()
        }

        guard let ad = rewardedAd else { return false }

        isLoading = true
        rewardEarned = false

        return await withCheckedContinuation { cont in
            self.showContinuation = cont

            ad.present(from: vc) { [weak self] in
                guard let self else { return }
                self.rewardEarned = true
                print("✅ Reward earned callback fired")
            }
        }
    }
}

// MARK: - FullScreenContentDelegate
extension AdMobRewardedManager: FullScreenContentDelegate {

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad dismissed ✅ rewardEarned=\(rewardEarned)")
        isLoading = false

        rewardedAd = nil
        isReady = false

        showContinuation?.resume(returning: rewardEarned)
        showContinuation = nil

        // ✅ грузим следующую только если НЕ premium
        if canShowAds { preload() }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad failed to present:", error)
        isLoading = false
        rewardedAd = nil
        isReady = false

        showContinuation?.resume(returning: false)
        showContinuation = nil

        if canShowAds { preload() }
    }
}
