//
//  RootView.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI
import StoreKit

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @StateObject private var store = StoreKitManager.shared

    var body: some View {
        Group {
            if !hasOnboarded {
                OnboardingView(onFinish: { hasOnboarded = true })
            } else if !store.hasEntitlement {
                PaywallView()
                    .environmentObject(store)
            } else {
                MainTabView()
                    .environmentObject(store)
            }
        }
    }
}
