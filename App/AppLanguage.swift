//
//  AppLanguage.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 06.01.2026.
//

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case en
    case ru

    var id: String { rawValue }

    var localeId: String? {
        switch self {
        case .system: return nil
        case .en: return "en"
        case .ru: return "ru"
        }
    }

    var locale: Locale {
        if let id = localeId { return Locale(identifier: id) }
        return .current
    }

    /// Заголовок для Picker — НЕ хардкодим по-хорошему, но можно оставить так.
    /// Если хочешь — сделаем ключи settings_language_system/en/ru.
    var title: String {
        switch self {
        case .system: return "System"
        case .en: return "English"
        case .ru: return "Русский"
        }
    }
}

enum Localization {
    static func bundle(for lang: AppLanguage) -> Bundle {
        guard let id = lang.localeId else { return .main }
        guard let path = Bundle.main.path(forResource: id, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }
}

enum L10n {
    /// Используй для НЕ-SwiftUI строк (например лог, форматирование, модели).
    static func s(_ key: String, lang: AppLanguage) -> String {
        NSLocalizedString(
            key,
            tableName: "Localizable",
            bundle: Localization.bundle(for: lang),
            value: key,
            comment: ""
        )
    }

    /// String + format (printf-style: %@, %d, etc.)
    static func f(_ key: String, lang: AppLanguage, _ args: CVarArg...) -> String {
        let format = s(key, lang: lang)
        return String(format: format, arguments: args)
    }

    /// ВАЖНО: НЕ делаем Text(verbatim:) тут.
    /// Для SwiftUI используй Text("key") и .environment(\.locale, ...)
}
