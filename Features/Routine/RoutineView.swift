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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection

                progressCalendar

                if let error = viewModel.errorText {
                    errorBanner(text: error)
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
        .navigationTitle("DAILY ROUTINE")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.configure(context: modelContext) }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Structured practices")
                .font(.headline)
            Text("Follow the suggested flow, regenerate a new one, or save it for later.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let plan = viewModel.plan {
                statusBadge(status: plan.status)
            }

            HStack(spacing: 10) {
                headerButton(title: "Reset Progress", icon: "gobackward", isDisabled: !viewModel.canResetPlan) { viewModel.resetProgress() }
                headerButton(title: "Regenerate", icon: "arrow.clockwise") {
                    Task { await viewModel.regenerate() }
                }
                headerButton(title: "Save", icon: "tray.and.arrow.down.fill", isDisabled: viewModel.plan == nil) { viewModel.savePlan() }
                headerButton(title: "Mark Done", icon: "checkmark.circle.fill", isDisabled: viewModel.plan == nil || viewModel.plan?.status == .done) { viewModel.markPlanDone() }
            }
        }
    }

    private var progressCalendar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This week")
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
            Text(status == .done ? "Marked as done" : "Active plan")
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var loadingState: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text("Generating your routine...")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("No routine yet")
                .font(.headline)
            Text("Tap Regenerate to get a fresh set of practices for the day.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            headerButton(title: "Regenerate", icon: "sparkles") {
                Task { await viewModel.regenerate() }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func routineContent(plan: RoutinePlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if plan.status == .done {
                banner(text: "Routine marked as done. Regenerate when you're ready for a fresh flow.")
            } else if let next = plan.nextIncomplete {
                banner(text: "Next: \(next.title) • \(next.durationMinutes) min")
            } else {
                banner(text: "Great job! All practices are done.")
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
                Text("\(item.durationMinutes) min")
                    .font(.caption.bold())
                    .padding(8)
                    .background(Color.black.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack {
                if item.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
                    Text("Pending")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if item.isCompleted {
                    Button {
                        viewModel.markUndone(item: item)
                    } label: {
                        Text("Mark as Pending")
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
                        Text("Mark as Done")
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

    private var dayEntries: [DayEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let weekdayIndex = max(calendar.component(.weekday, from: day) - 1, 0)
            let short = calendar.shortWeekdaySymbols[weekdayIndex]
            let isDone = viewModel.completionHistory[day] ?? false
            return DayEntry(day: day, short: short.uppercased(), isDone: isDone, isToday: calendar.isDate(day, inSameDayAs: today))
        }.reversed()
    }
}

private struct DayEntry: Identifiable {
    var id: Date { day }
    let day: Date
    let short: String
    let isDone: Bool
    let isToday: Bool
}
