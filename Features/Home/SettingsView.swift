//
//  SettingsView.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 31.12.2025.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var paywall: PaywallPresenter
    @EnvironmentObject private var apphud: ApphudManager

    @AppStorage("userName") private var userName: String = ""
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.system.rawValue
    @AppStorage("paywall_skipped_once") private var paywallSkippedOnce: Bool = false

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

            // ✅ Premium section
            Section {
                Button {
                    Analytics.event("settings_premium_tap")

                    if apphud.hasPremium {
                        // Открыть управление подписками Apple
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    } else {
                        // Показать paywall
                        paywall.present()
                    }

                } label: {
                    HStack {
                        Text(apphud.hasPremium
                             ? L10n.s("settings_manage_subscription", lang: uiLang)
                             : L10n.s("settings_get_premium", lang: uiLang))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }

                // опционально: дать “сбросить отказ”, чтобы снова показывался paywall на старте
                if paywallSkippedOnce {
                    Button {
                        paywallSkippedOnce = false
                        Analytics.event("settings_reset_paywall_skip")
                    } label: {
                        Text(L10n.s("settings_reset_paywall", lang: uiLang))
                            .foregroundStyle(.secondary)
                    }
                }

            } header: {
                Text(L10n.s("settings_premium_section", lang: uiLang))
            }

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
