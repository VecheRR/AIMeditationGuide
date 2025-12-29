//
//  OnboardingView.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack {
                Spacer()
                Text("Onboarding \(page + 1)/4")
                    .font(.title2)

                Spacer()

                Button(page == 3 ? "START NOW" : "NEXT") {
                    if page == 3 { onFinish() }
                    else { page += 1 }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding()
            }
        }
    }
}
