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
    @AppStorage("appLanguage") private var appLanguage = Locale.current.languageCode ?? "en"

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.locale, Locale(identifier: appLanguage))
        }
        .modelContainer(AppModelContainer.container)
    }
}
