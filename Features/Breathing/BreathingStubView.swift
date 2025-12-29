//
//  BreathingStubView.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI

struct BreathingStubView: View {
    var body: some View {
        ZStack {
            AppBackground()
            Text("Breathing — next step")
                .font(.title2.bold())
        }
        .navigationTitle("BREATHING")
        .navigationBarTitleDisplayMode(.inline)
    }
}
