//
//  BreathingSetupView.swift
//  AIMeditationGuide
//
//  Created by Vladislav on 29.12.2025.
//

import SwiftUI

struct BreathingSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = BreathingViewModel()

    @State private var showMoodPicker = false
    @State private var showDurationPicker = false
    @State private var startSession = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 20) {
                    header

                    illustration

                    Text("Create a breathing exercise\nthat matches your current state")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 12) {
                        optionRow(
                            title: "Mood Check-in",
                            value: vm.mood?.rawValue,
                            icon: "target"
                        ) {
                            showMoodPicker = true
                        }

                        optionRow(
                            title: "Duration",
                            value: vm.duration.map { "\($0.rawValue) min" },
                            icon: "timer"
                        ) {
                            showDurationPicker = true
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()

                    PrimaryButton(
                        title: "START SESSION",
                        isEnabled: vm.canStart
                    ) {
                        startSession = true
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationDestination(isPresented: $startSession) {
                BreathingSessionView(vm: vm)
            }
            .sheet(isPresented: $showMoodPicker) {
                MoodPickerView(selected: $vm.mood)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showDurationPicker) {
                DurationPickerView(selected: $vm.duration)
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Components

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.black)
                    .padding(10)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Circle())
            }

            Spacer()

            Text("BREATHING EXERCISE")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Spacer()

            // симметрия
            Color.clear.frame(width: 32)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var illustration: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white.opacity(0.35))
            .frame(height: 220)
            .overlay(
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.opacity(0.7))
            )
            .padding(.horizontal, 16)
    }

    private func optionRow(
        title: String,
        value: String?,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(value == nil ? .secondary : Color.white)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(value == nil ? Color.black.opacity(0.05) : Color.black)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(value ?? "Select")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.black)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color.white.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
