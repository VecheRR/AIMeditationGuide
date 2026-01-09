//
//  ApphudManager.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 07.01.2026.
//

import Foundation
import ApphudSDK
import StoreKit
import Combine

@MainActor
final class ApphudManager: ObservableObject {
    static let shared = ApphudManager()

    @Published private(set) var hasPremium: Bool = false
    @Published private(set) var products: [PaywallProductVM] = []
    @Published private(set) var isLoading: Bool = false
    @Published var lastError: String?
    @Published var isReady: Bool = false

    // MARK: - DEBUG premium override
    private static let debugKey = "debug_force_premium"

    @Published var debugForcePremium: Bool = UserDefaults.standard.bool(forKey: debugKey) {
        didSet {
            UserDefaults.standard.set(debugForcePremium, forKey: Self.debugKey)

            // ✅ очень важно: после тумблера сразу “подтянуть” логику
            objectWillChange.send()

            // ✅ если включили premium — сразу выключим рекламу и сбросим загруженные ads
            if premiumActive {
                AdMobRewardedManager.shared.disableAdsForPremium()
            } else {
                // если выключили — можно заново начать подгрузку
                AdMobRewardedManager.shared.preload()
            }
        }
    }

    /// ✅ Это должен использовать ВЕСЬ UI/логика
    var premiumActive: Bool {
#if DEBUG
        return debugForcePremium || hasPremium
#else
        return hasPremium
#endif
    }

    // Apphud placement/paywall IDs
    private let placementID = "placement_main"
    private let expectedPaywallID = "main_paywall"

    private var didBootstrap = false
    private init() {}

    func start() {
        guard !didBootstrap else { return }
        didBootstrap = true

        refreshStatus()

#if DEBUG
        debugForcePremium = UserDefaults.standard.bool(forKey: Self.debugKey)
#endif

        loadPaywallProducts()

        // optional debug (StoreKit2)
        Task {
            do {
                let ids = ["sonicforge_weekly", "sonicforge_monthly", "sonicforge_yearly"]
                let sk2 = try await Product.products(for: ids)
                print("StoreKit2 products:", sk2.map { $0.id })
            } catch {
                print("StoreKit2 error:", error)
            }
        }
    }

    func refreshStatus() {
        hasPremium = Apphud.hasActiveSubscription() || Apphud.hasPremiumAccess()

        // ✅ если реальный premium стал активен — выключаем рекламу
        if premiumActive {
            AdMobRewardedManager.shared.disableAdsForPremium()
        }
    }

    func loadPaywallProducts() {
        isLoading = true
        isReady = false
        lastError = nil
        products = []

        Apphud.fetchPlacements { [weak self] placements, error in
            guard let self else { return }

            Task { @MainActor in
                defer {
                    self.isLoading = false
                    self.refreshStatus()
                    self.isReady = true
                }

                if let error {
                    self.lastError = "Apphud placements error: \(error.localizedDescription)"
                    return
                }

                let allIDs = placements.map { $0.identifier }
                print("PLACEMENTS:", allIDs)

                guard let placement = placements.first(where: { $0.identifier == self.placementID }) else {
                    self.lastError = "Apphud: Placement '\(self.placementID)' не найден. Есть: \(allIDs.joined(separator: ", "))"
                    return
                }

                guard let paywall = placement.paywall else {
                    self.lastError = "Apphud: у placement '\(self.placementID)' нет paywall. Привяжи paywall \(self.expectedPaywallID)."
                    return
                }

                Apphud.paywallShown(paywall)

                let apphudProducts = paywall.products
                print("APPHUD PAYWALL PRODUCTS:", apphudProducts.map { $0.productId })

                guard !apphudProducts.isEmpty else {
                    self.lastError = "Paywall найден, но products пустые. Проверь привязку IAP к paywall в Apphud."
                    return
                }

                let mapped: [PaywallProductVM] = apphudProducts.map { p in
                    let productId = p.productId

                    let name: String = {
                        let t = p.skProduct?.localizedTitle.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        return t.isEmpty ? productId : t
                    }()

                    let price = p.skProduct?.formattedPrice ?? ""

                    let unit: String? = {
                        let id = productId.lowercased()
                        if id.contains("weekly") { return "week" }
                        if id.contains("monthly") { return "month" }
                        if id.contains("yearly") { return "year" }
                        return nil
                    }()

                    let hasTrial = (p.skProduct?.introductoryPrice != nil)

                    return PaywallProductVM(
                        id: productId,
                        displayName: name,
                        displayPrice: price,
                        periodUnit: unit,
                        hasTrial: hasTrial,
                        apphudProduct: p
                    )
                }

                self.products = mapped

                if mapped.allSatisfy({ $0.displayPrice.isEmpty }) {
                    self.lastError = "Apphud продукты пришли, но цены пустые. Проверь StoreKit Configuration / Sandbox / доступность IAP."
                }
            }
        }
    }

    func purchase(_ vm: PaywallProductVM) {
        lastError = nil
        isLoading = true

        Apphud.purchase(vm.apphudProduct) { [weak self] result in
            guard let self else { return }
            Task { @MainActor in
                self.isLoading = false

                if result.success {
                    self.refreshStatus()
                } else {
                    self.lastError = result.error?.localizedDescription ?? "Purchase failed"
                }
            }
        }
    }

    func restore() {
        lastError = nil
        isLoading = true

        Apphud.restorePurchases { [weak self] result in
            guard let self else { return }
            Task { @MainActor in
                self.isLoading = false

                if result.success {
                    self.refreshStatus()
                } else {
                    self.lastError = result.error?.localizedDescription ?? "Restore failed"
                }
            }
        }
    }
}

// MARK: - Helpers

private extension SKProduct {
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price) ?? "\(price)"
    }
}
