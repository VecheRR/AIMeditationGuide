//
//  DurationPickerView.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 29.12.2025.
//

import SwiftUI

struct DurationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: BreathingDuration?

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 14) {
                header

                VStack(spacing: 10) {
                    ForEach(BreathingDuration.allCases, id: \.self) { dur in
                        pill(title: "\(dur.rawValue) min", isSelected: selected == dur) {
                            selected = dur
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.black)
                    .padding(10)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Circle())
            }

            Spacer()

            Text("DURATION")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Spacer()

            Color.clear.frame(width: 32)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private func pill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.black)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.black)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .background(Color.white.opacity(isSelected ? 0.9 : 0.75))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? Color.black.opacity(0.35) : Color.clear, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
