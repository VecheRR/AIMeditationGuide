//
//  RoutineViewModel.swift
//  AIMeditationGuide
//
//  Created by OpenAI ChatGPT.
//

import Foundation
import SwiftData

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

    func start() {
        guard let plan else { return }
        highlightedItemID = plan.status == .done ? nil : plan.nextIncomplete?.id
    }

    func markDone(item: RoutineItem) {
        guard let context, var currentItems = plan?.items else { return }
        if let index = currentItems.firstIndex(of: item) {
            currentItems[index].isCompleted = true
            plan?.items = currentItems
            if plan?.nextIncomplete == nil {
                plan?.status = .done
            }
            highlightedItemID = plan?.nextIncomplete?.id
            try? context.save()
        }
    }

    func markUndone(item: RoutineItem) {
        guard let context, var currentItems = plan?.items else { return }
        if let index = currentItems.firstIndex(of: item) {
            currentItems[index].isCompleted = false
            plan?.items = currentItems
            plan?.status = .active
            highlightedItemID = plan?.nextIncomplete?.id
            try? context.save()
        }
    }

    func markPlanDone() {
        guard let context, var currentItems = plan?.items else { return }
        for index in currentItems.indices {
            currentItems[index].isCompleted = true
        }

        plan?.items = currentItems
        plan?.status = .done
        highlightedItemID = nil
        try? context.save()
    }
}
