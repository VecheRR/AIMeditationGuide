//
//  RootView.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 29.12.2025.
//

import SwiftUI
import Combine

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("didTrackFirstOpen") private var didTrackFirstOpen = false

    @StateObject private var apphud: ApphudManager = .shared

    var body: some View {
        Group {
            if !hasOnboarded {
                OnboardingView(onFinish: {
                    Analytics.event("onboarding_complete")
                    hasOnboarded = true
                })
//            } else if !apphud.hasPremium {
//                PaywallView()
//                    .environmentObject(apphud)
            } else {
                MainTabView()
                    .environmentObject(apphud)
            }
        }
        .task {
            apphud.start()   // <- ок, если start() реально функция
        }
        .onAppear {
            if !didTrackFirstOpen {
                Analytics.event("first_open")
                didTrackFirstOpen = true
            }
        }
    }
}
