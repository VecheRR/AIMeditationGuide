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
    @Published var errorText: String?
    @Published var highlightedItemID: UUID?

    private let generator = RoutineGeneratorService()
    private var context: ModelContext?

    func configure(context: ModelContext) {
        self.context = context
        if plan == nil {
            loadLatest()
        }
    }

    func loadLatest() {
        guard let context else { return }
        let descriptor = FetchDescriptor<RoutinePlan>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        if let latest = try? context.fetch(descriptor).first {
            plan = latest
            highlightedItemID = latest.status == .done ? nil : latest.nextIncomplete?.id
        }
        refreshCompletionHistory()
    }

    func generate() async {
        guard let context else { return }
        isLoading = true
        errorText = nil
        defer { isLoading = false }

        do {
            let practices = try await generator.generateRoutine()
            let data = try JSONEncoder().encode(practices)
            guard let json = String(data: data, encoding: .utf8) else { return }

            let newPlan = RoutinePlan(itemsJSON: json, isSaved: false, status: .active)
            context.insert(newPlan)
            try context.save()

            plan = newPlan
            highlightedItemID = newPlan.nextIncomplete?.id
            refreshCompletionHistory()
        } catch {
            errorText = error.localizedDescription
        }
    }

    func savePlan() {
        guard let context, let plan else { return }
        plan.isSaved = true
        try? context.save()
    }

    func regenerate() async {
        await generate()
    }

    func resetProgress() {
        guard let context, var items = plan?.items else { return }

        for index in items.indices {
            items[index].isCompleted = false
        }

        plan?.items = items
        plan?.status = .active
        plan?.completedAt = nil
        highlightedItemID = plan?.nextIncomplete?.id
        try? context.save()
        refreshCompletionHistory()
    }

    func markDone(item: RoutineItem) {
        guard let context, var currentItems = plan?.items else { return }
        if let index = currentItems.firstIndex(of: item) {
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
    }

    func markUndone(item: RoutineItem) {
        guard let context, var currentItems = plan?.items else { return }
        if let index = currentItems.firstIndex(of: item) {
            currentItems[index].isCompleted = false
            plan?.items = currentItems
            plan?.status = .active
            plan?.completedAt = nil
            highlightedItemID = plan?.nextIncomplete?.id
            try? context.save()
            refreshCompletionHistory()
        }
    }

    func markPlanDone() {
        guard let context, var currentItems = plan?.items else { return }
        for index in currentItems.indices {
            currentItems[index].isCompleted = true
        }

        plan?.items = currentItems
        plan?.status = .done
        plan?.completedAt = .now
        highlightedItemID = nil
        try? context.save()
        refreshCompletionHistory()
    }

    @Published var completionHistory: [Date: Bool] = [:]

    var canResetPlan: Bool {
        guard let plan else { return false }
        let hasCompletedItems = plan.items.contains(where: { $0.isCompleted })
        return hasCompletedItems || plan.status == .done
    }

    private func refreshCompletionHistory() {
        guard let context else { return }
        let descriptor = FetchDescriptor<RoutinePlan>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let plans = (try? context.fetch(descriptor)) ?? []

        let calendar = Calendar.current
        var results: [Date: Bool] = [:]
        let today = calendar.startOfDay(for: .now)

        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let isDone = plans.contains { plan in
                guard let completedAt = plan.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: day)
            }
            results[day] = isDone
        }

        completionHistory = results
    }
}
