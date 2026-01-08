//
//  PaywallProductVM.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 07.01.2026.
//


import Foundation
import ApphudSDK

struct PaywallProductVM: Identifiable, Equatable {
    let id: String
    let displayName: String
    let displayPrice: String
    let periodUnit: String?   // "week" / "month" / "year" (для UI)
    let hasTrial: Bool
    let apphudProduct: ApphudProduct
}
