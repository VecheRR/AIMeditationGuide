//
//  RootView.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("isPro") private var isPro = false

    var body: some View {
        Group {
            if !hasOnboarded {
                OnboardingView(onFinish: { hasOnboarded = true })
            } else if !isPro {
                PaywallView(onClose: { isPro = true })
            } else {
                MainTabView()
            }
        }
    }
}
