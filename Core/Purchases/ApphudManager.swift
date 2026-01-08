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

// MARK: - ViewModel for Paywall product (если у тебя уже есть свой PaywallProductVM — УДАЛИ этот блок)

@MainActor
final class ApphudManager: ObservableObject {
    static let shared = ApphudManager()

    @Published private(set) var hasPremium: Bool = false
    @Published private(set) var products: [PaywallProductVM] = []
    @Published private(set) var isLoading: Bool = false
    @Published var lastError: String?
    @Published var isReady: Bool = false

    // Создай в Apphud → Placements identifier = "main" и привяжи к нему paywall main_paywall
    private let placementID = "placement_main"
    private let expectedPaywallID = "main_paywall"

    private var didBootstrap = false

    private init() {}

    /// Вызывай после старта SDK (у тебя старт уже в AppDelegate)
    func start() {
        // НЕ стартуем SDK тут, чтобы не было двойного старта.
        // В AppDelegate у тебя уже есть:
        // Apphud.start(apiKey: Keys.apphud)

        guard !didBootstrap else { return }
        didBootstrap = true

        refreshStatus()
        loadPaywallProducts()
        
        Task {
            do {
                let ids = ["sonicforge_weekly","sonicforge_monthly","sonicforge_yearly"]
                let products = try await Product.products(for: ids)
                print("StoreKit products:", products.map { $0.id })
            } catch {
                print("StoreKit error:", error)
            }
        }
    }

    func refreshStatus() {
        hasPremium = Apphud.hasActiveSubscription() || Apphud.hasPremiumAccess()
    }

    func loadPaywallProducts() {
        isLoading = true
        isReady = false
        lastError = nil
        products = []

        Apphud.fetchPlacements { [weak self] placements, error in
            guard let self else { return }
            defer { Task { @MainActor in self.isReady = true } }

            Task { @MainActor in
                defer {
                    self.isLoading = false
                    self.refreshStatus()
                    self.isReady = true          // ✅ ВСЕГДА СТАВИМ READY
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

                // необязательно, но полезно
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

private extension Optional where Wrapped == String {
    var nonEmptyOrNil: String? {
        guard let s = self?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return s
    }
}

private extension SKProduct {
    /// Форматированная цена, типа "₽199.00" / "$4.99"
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price) ?? "\(price)"
    }
}
