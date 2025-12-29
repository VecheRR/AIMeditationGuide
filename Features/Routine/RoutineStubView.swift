//
//  RoutineStubView.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI

struct RoutineStubView: View {
    var body: some View {
        ZStack {
            AppBackground()
            Text("Daily Routine — next step")
                .font(.title2.bold())
        }
        .navigationTitle("DAILY ROUTINE")
        .navigationBarTitleDisplayMode(.inline)
    }
}
