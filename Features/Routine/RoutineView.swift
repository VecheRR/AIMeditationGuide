//
//  RoutineView.swift
//  AIMeditationGuide
//
//  Created by OpenAI ChatGPT.
//

import SwiftUI
import SwiftData

struct RoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = RoutineViewModel()

    // Language (важно!)
    @AppStorage("appLanguage") private var appLanguageRaw: String = AppLanguage.system.rawValue
    private var lang: AppLanguage { AppLanguage(rawValue: appLanguageRaw) ?? .system }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection

                progressCalendar

                if let key = viewModel.errorKey {
                    errorBanner(text: L10n.s(key, lang: lang))
                }

                if viewModel.isLoading {
                    loadingState
                } else if let plan = viewModel.plan {
                    routineContent(plan: plan)
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(AppBackground())
        .navigationTitle(L10n.s("routine_title", lang: lang))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.configure(context: modelContext)
            viewModel.setLanguage(lang)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.s("routine_header_title", lang: lang))
                .font(.headline)

            Text(L10n.s("routine_header_subtitle", lang: lang))
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let plan = viewModel.plan {
                statusBadge(status: plan.status)
            }

            HStack(spacing: 10) {
                headerButton(
                    title: L10n.s("routine_btn_start", lang: lang),
                    icon: "play.fill",
                    isDisabled: viewModel.plan == nil
                ) { viewModel.start() }

                headerButton(
                    title: L10n.s("routine_btn_regenerate", lang: lang),
                    icon: "arrow.clockwise"
                ) {
                    Task { await viewModel.regenerate() }
                }

                headerButton(
                    title: L10n.s("routine_btn_save", lang: lang),
                    icon: "tray.and.arrow.down.fill",
                    isDisabled: viewModel.plan == nil
                ) { viewModel.savePlan() }

                headerButton(
                    title: L10n.s("routine_btn_mark_done", lang: lang),
                    icon: "checkmark.circle.fill",
                    isDisabled: viewModel.plan == nil || viewModel.plan?.status == .done
                ) { viewModel.markPlanDone() }
            }
        }
    }

    private func headerButton(title: String, icon: String, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title).font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(isDisabled ? 0.4 : 0.7))
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private func statusBadge(status: RoutineStatus) -> some View {
        HStack(spacing: 8) {
            Image(systemName: status == .done ? "checkmark.seal.fill" : "bolt.fill")
                .foregroundStyle(status == .done ? .green : .blue)

            Text(status == .done
                 ? L10n.s("routine_status_done", lang: lang)
                 : L10n.s("routine_status_active", lang: lang))
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Week calendar

    private var progressCalendar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.s("routine_week_title", lang: lang))
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(dayEntries, id: \.day) { entry in
                    VStack(spacing: 6) {
                        Text(entry.short)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Circle()
                            .fill(entry.isDone ? Color.green : Color.black.opacity(0.1))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(entry.isToday ? Color.blue : Color.clear, lineWidth: 2)
                                    .frame(width: 18, height: 18)
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text(L10n.s("routine_loading", lang: lang))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text(L10n.s("routine_empty_title", lang: lang))
                .font(.headline)

            Text(L10n.s("routine_empty_subtitle", lang: lang))
                .font(.footnote)
                .foregroundStyle(.secondary)

            headerButton(title: L10n.s("routine_btn_regenerate", lang: lang), icon: "sparkles") {
                Task { await viewModel.regenerate() }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Content

    private func routineContent(plan: RoutinePlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if plan.status == .done {
                banner(text: L10n.s("routine_banner_done", lang: lang))
            } else if let next = plan.nextIncomplete {
                banner(text: L10n.f("routine_banner_next_format", lang: lang, next.title, next.durationMinutes))
            } else {
                banner(text: L10n.s("routine_banner_all_done", lang: lang))
            }

            ForEach(plan.items) { item in
                routineCard(item: item)
            }
        }
    }

    private func banner(text: String) -> some View {
        HStack {
            Image(systemName: "leaf.fill")
                .foregroundStyle(.green)
            Text(text)
                .font(.footnote)
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func errorBanner(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(text)
                .font(.footnote)
        }
        .padding(12)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func routineCard(item: RoutineItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.headline)

                    Text(item.details)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(L10n.f("routine_minutes_format", lang: lang, item.durationMinutes))
                    .font(.caption.bold())
                    .padding(8)
                    .background(Color.black.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack {
                if item.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Text(L10n.s("routine_item_completed", lang: lang))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)

                    Text(L10n.s("routine_item_pending", lang: lang))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if item.isCompleted {
                    Button {
                        viewModel.markUndone(item: item)
                    } label: {
                        Text(L10n.s("routine_btn_mark_pending", lang: lang))
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.7))
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        viewModel.markDone(item: item)
                    } label: {
                        Text(L10n.s("routine_btn_mark_done_item", lang: lang))
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.8))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(viewModel.highlightedItemID == item.id ? 0.85 : 0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(viewModel.highlightedItemID == item.id ? Color.green : Color.clear, lineWidth: 2)
        )
    }

    // MARK: - Days

    private var dayEntries: [DayEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let localeID: String = {
            switch lang {
            case .ru: return "ru_RU"
            case .en: return "en_US"
            case .system: return Locale.current.identifier
            }
        }()

        let loc = Locale(identifier: localeID)

        // ВАЖНО: не берём calendar.shortWeekdaySymbols, потому что он зависит от Locale.current,
        // а нам нужно уважать appLanguage.
        let shortSymbols = Calendar(identifier: calendar.identifier).shortStandaloneWeekdaySymbols(with: loc)

        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }

            let weekdayIndex = max(calendar.component(.weekday, from: day) - 1, 0)
            let short = shortSymbols[safe: weekdayIndex] ?? ""

            let isDone = viewModel.completionHistory[day] ?? false
            let isToday = calendar.isDate(day, inSameDayAs: today)

            // Uppercase: делаем локально корректно
            let display = short.uppercased(with: loc)

            return DayEntry(day: day, short: display, isDone: isDone, isToday: isToday)
        }
        .reversed()
    }
}

// MARK: - Helpers

private struct DayEntry: Identifiable {
    var id: Date { day }
    let day: Date
    let short: String
    let isDone: Bool
    let isToday: Bool
}

private extension Calendar {
    func shortStandaloneWeekdaySymbols(with locale: Locale) -> [String] {
        var cal = self
        cal.locale = locale
        return cal.shortStandaloneWeekdaySymbols
    }
}

private extension Array {
    subscript(safe idx: Int) -> Element? {
        guard idx >= 0, idx < count else { return nil }
        return self[idx]
    }
}
