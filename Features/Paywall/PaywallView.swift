//
//  PaywallView.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI

struct PaywallView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var apphud: ApphudManager

    @State private var selectedProductID: String?

    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.system.rawValue
    private var lang: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .system }

    @AppStorage("paywall_skipped_once") private var paywallSkippedOnce: Bool = false

    private let perkKeys: [String] = [
        "paywall_perk_unlimited",
        "paywall_perk_backgrounds",
        "paywall_perk_history",
        "paywall_perk_breathing"
    ]

    var body: some View {
        ZStack {
            // ⚠️ ВАЖНО: гарантированно видимый фон
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 16) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        perksCard
                        planPicker

                        if let error = apphud.lastError, !error.isEmpty {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 6)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                VStack(spacing: 10) {
                    PrimaryButton(title: primaryButtonTitle) {
                        purchaseSelected()
                    }
                    .disabled(apphud.isLoading || selectedProductID == nil)

                    Button {
                        Analytics.event("paywall_restore_tap", ["source": "paywall"])
                        apphud.restore()
                    } label: {
                        Text(L10n.s("paywall_restore", lang: lang))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .disabled(apphud.isLoading)

                    // ✅ единственный выход
                    Button {
                        Analytics.event("paywall_skip", ["source": "paywall"])
                        paywallSkippedOnce = true
                        isPresented = false
                    } label: {
                        Text(L10n.s("paywall_not_now", lang: lang))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                    .disabled(apphud.isLoading)

                    Text(L10n.s("paywall_disclaimer", lang: lang))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                        .padding(.horizontal, 24)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
            }
            .padding(.top, 18)
        }
        .onAppear {
            print("PAYWALL view appeared 👀")
            Analytics.event("paywall_open", ["source": "app_gate"])
        }
        .task {
            if apphud.products.isEmpty && !apphud.isLoading {
                apphud.loadPaywallProducts()
            }
            if selectedProductID == nil {
                selectedProductID = apphud.products.first?.id
            }
        }
        .onChange(of: apphud.hasPremium) { _, isPremium in
            if isPremium {
                isPresented = false
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(L10n.s("paywall_title", lang: lang))
                .font(.system(size: 30, weight: .semibold))
                .multilineTextAlignment(.center)

            Text(L10n.s("paywall_subtitle", lang: lang))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
    }

    private var perksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 74, height: 74)

                    Image(systemName: "star.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.s("paywall_perks_title", lang: lang))
                        .font(.headline)

                    Text(L10n.s("paywall_perks_subtitle", lang: lang))
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

                        Text(L10n.s(key, lang: lang))
                            .font(.footnote)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var planPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.s("paywall_choose_plan", lang: lang))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                ForEach(apphud.products, id: \.id) { vm in
                    Button {
                        selectedProductID = vm.id
                        Analytics.event("paywall_plan_select", ["product_id": vm.id])
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(vm.displayName.uppercased())
                                    .font(.caption.weight(.semibold))

                                Text(vm.displayPrice.isEmpty ? "—" : vm.displayPrice)
                                    .font(.title3.weight(.semibold))

                                if let d = detail(for: vm) {
                                    Text(d)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: selectedProductID == vm.id ? "largecircle.fill.circle" : "circle")
                                .font(.title3)
                                .foregroundStyle(.primary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(selectedProductID == vm.id ? Color.primary : Color.primary.opacity(0.12), lineWidth: 1.2)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                if apphud.products.isEmpty {
                    ProgressView().frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var primaryButtonTitle: String {
        if apphud.isLoading { return L10n.s("paywall_processing", lang: lang) }
        return L10n.s("paywall_continue", lang: lang)
    }

    private func detail(for vm: PaywallProductVM) -> String? {
        guard let unit = vm.periodUnit else { return nil }
        switch unit {
        case "month": return L10n.s("paywall_detail_cancel_anytime", lang: lang)
        case "year": return L10n.s("paywall_detail_save_vs_monthly", lang: lang)
        default: return nil
        }
    }

    private func purchaseSelected() {
        guard let vm = apphud.products.first(where: { $0.id == selectedProductID }) else { return }
        Analytics.event("paywall_purchase_tap", ["product_id": vm.id])
        apphud.purchase(vm)
    }
}
