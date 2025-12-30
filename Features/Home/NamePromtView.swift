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

    var body: some View {
        VStack(spacing: 14) {
            Text("What's your name?")
                .font(.title2.weight(.semibold))

            Text("We’ll use it to personalize your Home screen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("Your name", text: $temp)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .padding(.top, 6)

            Button {
                let cleaned = temp.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !cleaned.isEmpty else { return }
                name = cleaned
                dismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.black)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(temp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button("Not now") {
                dismiss()
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.top, 2)
        }
        .padding(20)
        .onAppear {
            temp = name
        }
    }
}
