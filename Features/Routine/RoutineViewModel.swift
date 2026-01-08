//
//  RoutineViewModel.swift
//  AIMeditationGuide
//
//  Created by OpenAI ChatGPT.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class RoutineViewModel: ObservableObject {
    @Published private(set) var plan: RoutinePlan?
    @Published var isLoading = false

    // Вместо сырых error.localizedDescription (часто на EN)
    @Published var errorKey: String?
    @Published var errorDebug: String?

    @Published var highlightedItemID: UUID?
    @Published var completionHistory: [Date: Bool] = [:]

    private let generator = RoutineGeneratorService()
    private var context: ModelContext?
    
    private var appLang: AppLanguage = .system
    func setLanguage(_ lang: AppLanguage) { self.appLang = lang }

    func configure(context: ModelContext) {
        self.context = context
        if plan == nil { loadLatest() }
    }

    func loadLatest() {
        guard let context else { return }
        let descriptor = FetchDescriptor<RoutinePlan>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        if let latest = try? context.fetch(descriptor).first {
            plan = latest
            highlightedItemID = latest.status == .done ? nil : latest.nextIncomplete?.id
        }

        refreshCompletionHistory()
    }

    func generate() async {
        guard let context else { return }
        isLoading = true
        errorKey = nil
        errorDebug = nil
        defer { isLoading = false }

        do {
            let practices = try await generator.generateRoutine(context: makeGenerationContext(), lang: appLang)
            let data = try JSONEncoder().encode(practices)
            guard let json = String(data: data, encoding: .utf8) else {
                errorKey = "routine_error_encoding"
                return
            }

            let newPlan = RoutinePlan(itemsJSON: json, isSaved: false, status: .active)
            context.insert(newPlan)
            try context.save()

            plan = newPlan
            highlightedItemID = newPlan.nextIncomplete?.id
            refreshCompletionHistory()
        } catch {
            // 1) ключ для UI
            errorKey = mapErrorToKey(error)

            // 2) дебаг-инфо (можешь убрать если не нужно)
            errorDebug = String(describing: error)
            #if DEBUG
            print("Routine generate error:", error)
            #endif
        }
    }

    func regenerate() async {
        await generate()
    }

    func savePlan() {
        guard let context, let plan else { return }
        plan.isSaved = true
        try? context.save()
    }

    func start() {
        guard let context, var items = plan?.items else { return }

        for i in items.indices { items[i].isCompleted = false }

        plan?.items = items
        plan?.status = .active
        plan?.completedAt = nil
        highlightedItemID = plan?.nextIncomplete?.id

        try? context.save()
        refreshCompletionHistory()
    }

    func markDone(item: RoutineItem) {
        guard let context, var currentItems = plan?.items else { return }
        guard let index = currentItems.firstIndex(of: item) else { return }

        currentItems[index].isCompleted = true
        plan?.items = currentItems

        if plan?.nextIncomplete == nil {
            plan?.status = .done
            plan?.completedAt = .now
        }

        highlightedItemID = plan?.nextIncomplete?.id
        try? context.save()
        refreshCompletionHistory()
    }

    func markUndone(item: RoutineItem) {
        guard let context, var currentItems = plan?.items else { return }
        guard let index = currentItems.firstIndex(of: item) else { return }

        currentItems[index].isCompleted = false
        plan?.items = currentItems
        plan?.status = .active
        plan?.completedAt = nil

        highlightedItemID = plan?.nextIncomplete?.id
        try? context.save()
        refreshCompletionHistory()
    }

    func markPlanDone() {
        guard let context, var currentItems = plan?.items else { return }

        for i in currentItems.indices { currentItems[i].isCompleted = true }

        plan?.items = currentItems
        plan?.status = .done
        plan?.completedAt = .now
        highlightedItemID = nil

        try? context.save()
        refreshCompletionHistory()
    }

    // MARK: - Completion history

    private func refreshCompletionHistory() {
        guard let context else { return }
        let descriptor = FetchDescriptor<RoutinePlan>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let plans = (try? context.fetch(descriptor)) ?? []

        let calendar = Calendar.current
        var results: [Date: Bool] = [:]
        let today = calendar.startOfDay(for: .now)

        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let isDone = plans.contains { p in
                guard let completedAt = p.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: day)
            }
            results[day] = isDone
        }

        completionHistory = results
    }

    // MARK: - Generation context

    private func makeGenerationContext() -> RoutineGenerationContext {
        guard let context else { return .basic() }

        let descriptor = FetchDescriptor<RoutinePlan>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let plans = (try? context.fetch(descriptor)) ?? []

        let recentPracticeItems: [RoutineGenerationContext.RecentPractice] = plans
            .prefix(3)
            .flatMap { plan in
                plan.items.map { item in
                    RoutineGenerationContext.RecentPractice(
                        title: item.title,
                        completed: item.isCompleted,
                        durationMinutes: item.durationMinutes
                    )
                }
            }

        return RoutineGenerationContext(
            referenceDate: .now,
            goals: ["calm focus", "consistent routine"],
            recentPractices: Array(recentPracticeItems.prefix(10))
        )
    }

    // MARK: - Error mapping (ключи для локализации)

    private func mapErrorToKey(_ error: Error) -> String {
        let ns = error as NSError

        // частые сетевые кейсы
        if ns.domain == NSURLErrorDomain {
            switch ns.code {
            case NSURLErrorNotConnectedToInternet:
                return "routine_error_no_internet"
            case NSURLErrorTimedOut:
                return "routine_error_timeout"
            default:
                return "routine_error_network"
            }
        }

        // если сервис кидает что-то своё — можно расширить позже
        return "routine_error_generic"
    }
}
