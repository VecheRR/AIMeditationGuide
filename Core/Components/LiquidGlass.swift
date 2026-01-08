//
//  Untitled.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 07.01.2026.
//

import SwiftUI

struct LiquidGlass: ViewModifier {
    var cornerRadius: CGFloat = 24
    var strokeOpacity: CGFloat = 0.25

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(strokeOpacity), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 10)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 24, strokeOpacity: CGFloat = 0.25) -> some View {
        modifier(LiquidGlass(cornerRadius: cornerRadius, strokeOpacity: strokeOpacity))
    }
}
