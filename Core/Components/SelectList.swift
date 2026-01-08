//
//  SelectList.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI

struct SelectListRow: Identifiable, Hashable {
    let id: String      // стабильный ID (rawValue / key)
    let title: String   // локализованный текст для UI
}

struct SelectList: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let rows: [SelectListRow]
    let selectedID: String?
    let onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(rows) { row in
                            Button {
                                onSelect(row.id)
                                dismiss()
                            } label: {
                                Text(row.title)
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.white.opacity(0.7))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(alignment: .trailing) {
                                        if selectedID == row.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .padding(.trailing, 14)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.black)
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 16)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "chevron.left") }
                }
            }
        }
    }
}
