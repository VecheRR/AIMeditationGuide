//
//  AIMeditationGuideApp.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI
import SwiftData

@main
struct AIMeditationGuideApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(AppModelContainer.container)
    }
}
