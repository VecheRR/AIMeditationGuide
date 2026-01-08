//
//  AdMobRewardedManager.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 07.01.2026.
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
        // Тестовый rewarded ID (поменяешь на свой в проде)
        // ca-app-pub-3940256099942544/5224354917
        Bundle.main.object(forInfoDictionaryKey: "ADMOB_REWARDED_AD_UNIT_ID") as? String ?? "ca-app-pub-3940256099942544/5224354917"
    }

    private var rewardEarned: Bool = false
    private var showContinuation: CheckedContinuation<Bool, Never>?

    func preload() {
        guard !isLoading else { return }
        isLoading = true
        isReady = false

        let request = Request()
        RewardedAd.load(with: adUnitId, request: request) { [weak self] ad, error in
            guard let self else { return }
            Task { @MainActor in
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

    /// Возвращает true ТОЛЬКО если пользователь реально получил награду.
    func show(from vc: UIViewController) async -> Bool {
        // если рекламы нет — попробуем подгрузить
        if rewardedAd == nil {
            preload()
        }

        // ждём чуть-чуть, если грузится (не бесконечно)
        if rewardedAd == nil {
            // можно сделать улучшение: ждать isReady через async stream
            return false
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

extension AdMobRewardedManager: FullScreenContentDelegate {

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad dismissed ✅ rewardEarned=\(rewardEarned)")
        isLoading = false

        // Сбрасываем и сразу грузим следующую
        rewardedAd = nil
        isReady = false
        preload()

        // ВАЖНО: завершаем await именно тут (после закрытия)
        showContinuation?.resume(returning: rewardEarned)
        showContinuation = nil
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad failed to present:", error)
        isLoading = false
        rewardedAd = nil
        isReady = false
        preload()

        showContinuation?.resume(returning: false)
        showContinuation = nil
    }
}
