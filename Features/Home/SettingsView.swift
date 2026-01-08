//
//  SettingsView.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 31.12.2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.system.rawValue

    private var selectedLanguage: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage(rawValue: appLanguageRaw) ?? .system },
            set: { appLanguageRaw = $0.rawValue }
        )
    }

    private var uiLang: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .system
    }

    var body: some View {
        Form {
            Section {
                TextField(L10n.s("settings_name_placeholder", lang: uiLang), text: $userName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            } header: {
                Text(L10n.s("settings_profile_section", lang: uiLang))
            }

            Section {
                Picker(L10n.s("settings_language_title", lang: uiLang), selection: selectedLanguage) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(languageTitle(lang))
                            .tag(lang)
                    }
                }
            } header: {
                Text(L10n.s("settings_language_section", lang: uiLang))
            }
        }
        .navigationTitle(L10n.s("settings_title", lang: uiLang))
        .onAppear { Analytics.screen("settings") }
    }

    private func languageTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .system:
            return L10n.s("language_system", lang: uiLang)
        case .en:
            return L10n.s("language_english", lang: uiLang)
        case .ru:
            return L10n.s("language_russian", lang: uiLang)
        }
    }
}
