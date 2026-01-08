//
//  SKProduct+Price.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 07.01.2026.
//

import StoreKit

extension SKProduct {
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price) ?? "\(price)"
    }
}
