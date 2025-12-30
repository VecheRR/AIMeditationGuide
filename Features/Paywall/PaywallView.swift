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

    private let perks: [String] = [
        "Unlimited AI-generated meditations",
        "Full library of ambient backgrounds",
        "History & progress tracking",
        "Breathing exercises and routines"
    ]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    Text("Unlock AI Meditation")
                        .font(.system(size: 30, weight: .semibold))
                        .multilineTextAlignment(.center)
                    Text("Try premium for deeper guidance, soothing sounds, and mindful routines.")
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
                        Text("Restore purchases")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 12)

                Text("You won't be charged today. Cancel anytime during the trial. After the trial, your chosen plan renews automatically.")
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
                    Text("Premium features")
                        .font(.headline)
                    Text("Build a calming ritual with full access.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(perks, id: \.self) { item in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(item)
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
            Text("Choose your plan")
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
                                        .stroke(selectedProductID == product.id ? Color.black : Color.black.opacity(0.08), lineWidth: 1.2)
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
        .task { if selectedProductID == nil { selectedProductID = store.products.first?.id } }
    }

    private var primaryButtonTitle: String {
        if store.isProcessingPurchase { return "Processing..." }
        if let product = store.products.first(where: { $0.id == selectedProductID }),
           let offer = product.subscription?.introductoryOffer {
            return "Start \(offer.displayPrice) trial"
        }
        return "Continue"
    }

    private func badge(for product: Product) -> String? {
        if product.id.lowercased().contains("annual") { return "BEST VALUE" }
        if product.id.lowercased().contains("monthly") { return "FLEXIBLE" }
        if product.id.lowercased().contains("lifetime") { return "ONE-TIME" }
        return nil
    }

    private func detail(for product: Product) -> String? {
        if let subscription = product.subscription {
            let unit = subscription.subscriptionPeriod.unit
            switch unit {
            case .month: return "Cancel anytime"
            case .year: return "Save vs monthly"
            default: return nil
            }
        }
        return "Lifetime access"
    }

    private func purchaseSelected() async {
        guard let product = store.products.first(where: { $0.id == selectedProductID }) else { return }
        await store.purchase(product: product)
    }
}
