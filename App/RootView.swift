//
//  RootView.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 29.12.2025.
//

import SwiftUI

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("paywall_skipped_once") private var paywallSkippedOnce: Bool = false

    @StateObject private var apphud: ApphudManager = .shared
    @StateObject private var paywall = PaywallPresenter()

    @State private var didSchedulePaywall = false

    var body: some View {
        Group {
            if !hasOnboarded {
                OnboardingView(onFinish: {
                    Analytics.event("onboarding_complete")
                    hasOnboarded = true
                    didSchedulePaywall = false
                })
            } else {
                MainTabView()
                    .onAppear { schedulePaywallIfNeeded() }
            }
        }
        .environmentObject(apphud)
        .environmentObject(paywall) // ✅ Settings сможет дергать paywall.present()
        .task { apphud.start() }
        .onChange(of: hasOnboarded) { _, newValue in
            if newValue {
                didSchedulePaywall = false
                schedulePaywallIfNeeded()
            }
        }
        .onChange(of: apphud.hasPremium) { _, isPremium in
            if isPremium {
                paywall.dismiss()
            }
        }
        .fullScreenCover(item: $paywall.token) { _ in
            PaywallView(isPresented: Binding(
                get: { paywall.isPresented },
                set: { newValue in
                    if !newValue { paywall.dismiss() }   // ✅ важно
                }
            ))
            .environmentObject(apphud)
            .interactiveDismissDisabled(true)
        }
    }

    private func schedulePaywallIfNeeded() {
        guard hasOnboarded else { return }
        guard !paywallSkippedOnce else { return }
        guard !apphud.hasPremium else { return }
        guard !didSchedulePaywall else { return }

        didSchedulePaywall = true

        Task { @MainActor in
            // дать UI стабилизироваться (важно)
            try? await Task.sleep(nanoseconds: 450_000_000)

            // дождаться готовности Apphud, но не вечно
            let start = Date()
            while !apphud.isReady {
                try? await Task.sleep(nanoseconds: 150_000_000)
                if Date().timeIntervalSince(start) > 5 { break }
            }

            guard !paywallSkippedOnce, !apphud.hasPremium else { return }

            paywall.present()
            print("PAYWALL token set ✅")
        }
    }
}
