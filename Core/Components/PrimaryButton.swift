//
//  PrimaryButton.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Image(systemName: "arrow.right")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(isEnabled ? Color.black : Color.black.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(!isEnabled)
    }
}
