//
//  HomePromtView.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 31.12.2025.
//

import SwiftUI

struct NamePromptView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String

    @State private var temp: String = ""

    // ✅ Language like in the rest of the app
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.system.rawValue
    private var lang: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .system }

    private var cleanedTemp: String {
        temp.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(L10n.s("name_prompt_title", lang: lang))
                .font(.title2.weight(.semibold))

            Text(L10n.s("name_prompt_subtitle", lang: lang))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField(L10n.s("name_prompt_field_placeholder", lang: lang), text: $temp)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .padding(.top, 6)

            Button {
                guard !cleanedTemp.isEmpty else { return }
                name = cleanedTemp
                dismiss()
            } label: {
                Text(L10n.s("name_prompt_btn_continue", lang: lang))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.black)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(cleanedTemp.isEmpty)

            Button(L10n.s("name_prompt_btn_not_now", lang: lang)) {
                dismiss()
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.top, 2)
        }
        .padding(20)
        .onAppear { temp = name }
    }
}
