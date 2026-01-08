//
//  MainTabView.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 29.12.2025.
//

import SwiftUI

struct MainTabView: View {
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.system.rawValue
    private var lang: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .system }

    var body: some View {
        ZStack {
            TabView {
                HomeView()
                    .tabItem {
                        Label(L10n.s("tab_home", lang: lang), systemImage: "house.fill")
                    }

                HistoryView()
                    .tabItem {
                        Label(L10n.s("tab_history", lang: lang), systemImage: "clock.fill")
                    }

                SettingsView()
                    .tabItem {
                        Label(L10n.s("tab_settings", lang: lang), systemImage: "gearshape.fill")
                    }
            }
        }
    }
}
