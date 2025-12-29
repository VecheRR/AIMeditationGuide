//
//  PaywallView.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI

struct PaywallView: View {
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()
                Text("Paywall")
                    .font(.largeTitle.bold())

                Text("Mock paywall for MVP.")
                    .foregroundStyle(.secondary)

                Spacer()

                Button("NEXT") { onClose() }
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
