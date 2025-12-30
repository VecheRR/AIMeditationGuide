//
//  Untitled.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI

struct MainTabView: View {
    @AppStorage("appLanguage") private var appLanguage = Locale.current.languageCode ?? "en"

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }

            SettingsView(appLanguage: $appLanguage)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

private enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case russian = "ru"

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .english: "English"
        case .russian: "Русский"
        }
    }
}

private struct SettingsView: View {
    @Binding var appLanguage: String

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguage) ?? .english
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Language", selection: Binding(
                    get: { selectedLanguage },
                    set: { newValue in appLanguage = newValue.rawValue }
                )) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title).tag(language)
                    }
                }
            }
            .navigationTitle("SETTINGS")
        }
    }
}
