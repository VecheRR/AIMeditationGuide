//
//  SelectList.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI

struct SelectList: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let items: [String]
    let selected: String?
    let onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 10) {
                    ForEach(items, id: \.self) { item in
                        Button {
                            onSelect(item)
                            dismiss()
                        } label: {
                            Text(item)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(alignment: .trailing) {
                                    if selected == item {
                                        Image(systemName: "checkmark.circle.fill")
                                            .padding(.trailing, 14)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.black)
                    }
                    Spacer()
                }
                .padding(16)
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
