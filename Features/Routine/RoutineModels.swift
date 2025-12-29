//
//  RoutineModels.swift
//  AIMeditationGuide
//
//  Created by OpenAI ChatGPT.
//

import Foundation
import SwiftUI

struct RoutineItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var details: String
    var durationMinutes: Int
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, details: String, durationMinutes: Int, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.details = details
        self.durationMinutes = durationMinutes
        self.isCompleted = isCompleted
    }
}
