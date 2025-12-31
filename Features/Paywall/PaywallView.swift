//
//  PaywallView.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var store: StoreKitManager
    @State private var selectedProductID: String?

    // Храним ключи, а не английские строки
    private let perkKeys: [String] = [
        "paywall_perk_unlimited",
        "paywall_perk_backgrounds",
        "paywall_perk_history",
        "paywall_perk_breathing"
    ]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    Text(String(localized: "paywall_title"))
                        .font(.system(size: 30, weight: .semibold))
                        .multilineTextAlignment(.center)

                    Text(String(localized: "paywall_subtitle"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 8)

                VStack(spacing: 12) {
                    perksCard
                    planPicker

                    if let error = store.errorMessage, !error.isEmpty {
                        // Ошибка StoreKit/SDK — это системный текст, не локализуем
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }

                VStack(spacing: 12) {
                    PrimaryButton(title: primaryButtonTitle) {
                        Task { await purchaseSelected() }
                    }
                    .disabled(store.isProcessingPurchase || selectedProductID == nil)

                    Button(action: { Task { await store.restorePurchases() } }) {
                        Text(String(localized: "paywall_restore"))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 12)

                Text(String(localized: "paywall_disclaimer"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
    }

    private var perksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 74, height: 74)

                    Image(systemName: "star.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "paywall_perks_title"))
                        .font(.headline)

                    Text(String(localized: "paywall_perks_subtitle"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(perkKeys, id: \.self) { key in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(LocalizedStringKey(key))
                            .font(.footnote)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var planPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "paywall_choose_plan"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                ForEach(store.products, id: \.id) { product in
                    Button {
                        selectedProductID = product.id
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(product.displayName.uppercased())
                                        .font(.caption.weight(.semibold))

                                    if let badge = badge(for: product) {
                                        Text(badge)
                                            .font(.caption2.weight(.heavy))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.black.opacity(0.06))
                                            .clipShape(Capsule())
                                    }
                                }

                                Text(product.displayPrice)
                                    .font(.title3.weight(.semibold))

                                if let detail = detail(for: product) {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: selectedProductID == product.id ? "largecircle.fill.circle" : "circle")
                                .font(.title3)
                                .foregroundStyle(.black)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.72))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(
                                            selectedProductID == product.id ? Color.black : Color.black.opacity(0.08),
                                            lineWidth: 1.2
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                if store.products.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .task {
            if selectedProductID == nil {
                selectedProductID = store.products.first?.id
            }
        }
    }

    private var primaryButtonTitle: String {
        if store.isProcessingPurchase { return String(localized: "paywall_processing") }

        if let product = store.products.first(where: { $0.id == selectedProductID }),
           let offer = product.subscription?.introductoryOffer {
            // "Start %@ trial"
            return String(
                format: NSLocalizedString("paywall_start_trial_fmt", comment: ""),
                offer.displayPrice
            )
        }

        return String(localized: "paywall_continue")
    }

    private func badge(for product: Product) -> String? {
        let id = product.id.lowercased()
        if id.contains("annual") { return String(localized: "paywall_badge_best_value") }
        if id.contains("monthly") { return String(localized: "paywall_badge_flexible") }
        if id.contains("lifetime") { return String(localized: "paywall_badge_one_time") }
        return nil
    }

    private func detail(for product: Product) -> String? {
        if let subscription = product.subscription {
            switch subscription.subscriptionPeriod.unit {
            case .month:
                return String(localized: "paywall_detail_cancel_anytime")
            case .year:
                return String(localized: "paywall_detail_save_vs_monthly")
            default:
                return nil
            }
        }
        return String(localized: "paywall_detail_lifetime_access")
    }

    private func purchaseSelected() async {
        guard let product = store.products.first(where: { $0.id == selectedProductID }) else { return }
        await store.purchase(product: product)
    }
}
