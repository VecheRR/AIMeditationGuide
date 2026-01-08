import SwiftUI

struct BreathingSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = BreathingViewModel()

    // Language (важно!)
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.system.rawValue
    private var lang: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .system }

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

                    Text(L10n.s("bre_setup_subtitle", lang: lang))
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 12) {
                        optionRow(
                            titleKey: "bre_setup_mood_title",
                            valueText: vm.mood?.localizedTitleString,
                            placeholderKey: "common_select",
                            icon: "target"
                        ) { showMoodPicker = true }

                        optionRow(
                            titleKey: "bre_setup_duration_title",
                            valueText: vm.duration.map { $0.title(lang: lang) },
                            placeholderKey: "common_select",
                            icon: "timer"
                        ) { showDurationPicker = true }
                    }
                    .padding(.horizontal, 16)

                    Spacer()

                    PrimaryButton(
                        title: String(localized: "bre_setup_start_session"),
                        isEnabled: vm.canStart
                    ) {
                        Analytics.event("breathing_start", [
                            "mood": vm.mood?.rawValue ?? "unknown",
                            "duration_min": vm.duration?.rawValue ?? 0
                        ])
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

    private var header: some View {
        HStack {
            Spacer()

            Text(L10n.s("bre_setup_title", lang: lang))
                .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.top, 8)

            Spacer()

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
            .accessibilityHidden(true)
    }

    private func optionRow(
        titleKey: String,
        valueText: String?,
        placeholderKey: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        let hasValue = !(valueText ?? "").isEmpty

        return Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(!hasValue ? .secondary : Color.white)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle().fill(!hasValue ? Color.black.opacity(0.05) : Color.black)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.s(titleKey, lang: lang))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let valueText, !valueText.isEmpty {
                        Text(valueText)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.black)
                    } else {
                        Text(L10n.s(placeholderKey, lang: lang))
                            .font(.body.weight(.medium))
                            .foregroundStyle(.black)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .background(Color.white.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
