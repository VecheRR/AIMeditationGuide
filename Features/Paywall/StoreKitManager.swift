//
//  StoreKitManager.swift
//  AIMeditationGuide
//
//  Created by OpenAI Assistant.
//

import Foundation
import StoreKit

@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var entitlementActive: Bool = false
    @Published var isProcessingPurchase = false
    @Published var errorMessage: String?

    private let productIDs: Set<String> = [
        "aimeditation.pro.annual",
        "aimeditation.pro.monthly",
        "aimeditation.pro.lifetime"
    ]

    private let entitlementStorageKey = "hasProEntitlement"
    private var updatesTask: Task<Void, Never>?

    var hasEntitlement: Bool {
        entitlementActive || UserDefaults.standard.bool(forKey: entitlementStorageKey)
    }

    init() {
        updatesTask = Task { await listenForTransactions() }
        Task { await refreshProducts() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func refreshProducts() async {
        do {
            errorMessage = nil
            products = try await Product.products(for: Array(productIDs)).sorted(by: { $0.displayName < $1.displayName })
            try await updateCurrentEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase(product: Product) async {
        isProcessingPurchase = true
        defer { isProcessingPurchase = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateEntitlements(with: transaction)
                try? await updateCurrentEntitlements()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            try? await updateCurrentEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                await transaction.finish()
                await updateEntitlements(with: transaction)
                try? await updateCurrentEntitlements()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func updateCurrentEntitlements() async throws {
        var owned: Set<String> = []
        for await result in Transaction.currentEntitlements {
            let transaction = try checkVerified(result)
            owned.insert(transaction.productID)
        }
        purchasedProductIDs = owned
        entitlementActive = !owned.isEmpty
        UserDefaults.standard.set(entitlementActive, forKey: entitlementStorageKey)
    }

    private func updateEntitlements(with transaction: Transaction) async {
        guard productIDs.contains(transaction.productID) else { return }
        purchasedProductIDs.insert(transaction.productID)
        entitlementActive = true
        UserDefaults.standard.set(entitlementActive, forKey: entitlementStorageKey)
    }

    private func checkVerified(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .unverified:
            throw NSError(domain: "StoreKit", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unverified transaction"])
        case .verified(let transaction):
            return transaction
        }
    }
}
