//
//  MoodPickerView.swift
//  AIMeditationGuide
//

import SwiftUI

struct MoodPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: BreathingMood?

    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.system.rawValue
    private var lang: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .system }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 14) {
                header

                VStack(spacing: 10) {
                    ForEach(BreathingMood.allCases, id: \.self) { mood in
                        pill(title: mood.title(lang: lang), isSelected: selected == mood) {
                            selected = mood
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 8)
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.black)
                    .padding(10)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Circle())
            }

            Spacer()

            Text(L10n.s("bre_setup_mood_title", lang: lang))
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Spacer()

            Color.clear.frame(width: 32)
        }
        .padding(.horizontal, 16)
    }

    private func pill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.black)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(.black.opacity(isSelected ? 0.9 : 0.25))
            }
            .padding(14)
            .background(Color.white.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
