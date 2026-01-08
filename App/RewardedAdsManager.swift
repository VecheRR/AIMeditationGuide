//
//  RewardedAdsManager.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 07.01.2026.
//

import Foundation
import GoogleMobileAds
import UIKit

@MainActor
final class RewardedAdsManager: NSObject, ObservableObject {
    static let shared = RewardedAdsManager()

    @Published private(set) var isLoading = false
    @Published private(set) var isReady = false
    @Published var lastError: String?

    // Вставь свой ad unit id (rewarded) из AdMob
    // На тестах можно временно поставить:
    // let rewardedAdUnitId = "ca-app-pub-3940256099942544/1712485313"
    private let rewardedAdUnitId: String = {
        // Если хочешь, можешь хранить в Info.plist:
        // key: ADMOB_REWARDED_AD_UNIT_ID
        if let s = Bundle.main.object(forInfoDictionaryKey: "ADMOB_REWARDED_AD_UNIT_ID") as? String, !s.isEmpty {
            return s
        }
        return "ca-app-pub-3940256099942544/1712485313" // TEST
    }()

    private var rewardedAd: GADRewardedAd?
    private var pendingAction: (() -> Void)?
    private var earnedReward = false

    private override init() {
        super.init()
    }

    func load() {
        guard !isLoading else { return }
        isLoading = true
        lastError = nil
        isReady = false

        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: rewardedAdUnitId, request: request) { [weak self] ad, error in
            guard let self else { return }
            self.isLoading = false

            if let error {
                self.lastError = error.localizedDescription
                self.rewardedAd = nil
                self.isReady = false
                return
            }

            self.rewardedAd = ad
            self.rewardedAd?.fullScreenContentDelegate = self
            self.isReady = true
        }
    }

    /// Показываем rewarded. `onEarned` вызовем ТОЛЬКО если юзер реально “заработал награду”
    func showGate(onEarned: @escaping () -> Void) {
        pendingAction = onEarned
        earnedReward = false

        guard let rootVC = UIApplication.shared.topMostViewController else {
            lastError = "No root view controller to present ad."
            pendingAction = nil
            return
        }

        // Если не готово — грузим и покажем позже (пользователь нажал “Start” -> ждём готовности)
        guard let ad = rewardedAd else {
            load()
            return
        }

        isReady = false

        ad.present(fromRootViewController: rootVC) { [weak self] in
            // Это вызывается когда юзер earned reward (досмотрел)
            guard let self else { return }
            self.earnedReward = true
            // сам action вызовем в didDismiss, чтобы не стартовать медитацию "под рекламой"
        }
    }
}

// MARK: - GADFullScreenContentDelegate
extension RewardedAdsManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        let action = pendingAction
        let shouldRun = earnedReward

        pendingAction = nil
        earnedReward = false
        rewardedAd = nil

        // Сразу грузим следующую рекламу
        load()

        if shouldRun {
            action?()
        } else {
            // Не досмотрел — НЕ запускаем медитацию
            lastError = "Реклама не досмотрена — медитация не запущена."
        }
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        pendingAction = nil
        earnedReward = false
        rewardedAd = nil
        lastError = error.localizedDescription

        // перезагрузка
        load()
    }
}
