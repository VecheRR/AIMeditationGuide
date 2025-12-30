//
//  AppBackground.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI

struct AppBackground: View {
    var body: some View {
        GeometryReader { proxy in
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: proxy.size.width, height: proxy.size.height)
            .ignoresSafeArea()
        }
    }

    @Environment(\.colorScheme) private var colorScheme

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.08, green: 0.09, blue: 0.14),
                Color(red: 0.12, green: 0.13, blue: 0.2),
                Color(red: 0.16, green: 0.18, blue: 0.26)
            ]
        }

        return [
            Color(red: 0.93, green: 0.96, blue: 1.0),
            Color(red: 0.98, green: 0.96, blue: 0.94),
            Color.white
        ]
    }
}
