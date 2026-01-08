//
//  PaywallPresenter.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 09.01.2026.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class PaywallPresenter: ObservableObject {

    struct Token: Identifiable {
        let id = UUID()
    }

    @Published var token: Token? = nil

    // ✅ будет меняться, когда paywall закрыли
    @Published private(set) var lastDismissedAt: Date? = nil

    var isPresented: Bool { token != nil }

    func present() {
        token = nil
        // небольшой “ребаунс”, чтобы SwiftUI точно презентнул
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.token = Token()
        }
    }

    func dismiss() {
        token = nil
        lastDismissedAt = Date()
    }
}
