//
//  PaywallView.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 29.12.2025.
//

import SwiftUI

struct PaywallView: View {
    let onClose: () -> Void
    @State private var selectedPlan: PaywallPlan.ID = PaywallPlan.defaultSelection

    private let plans = PaywallPlan.defaultPlans

    private let perks: [String] = [
        "Unlimited AI-generated meditations",
        "Full library of ambient backgrounds",
        "History & progress tracking",
        "Breathing exercises and routines"
    ]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 18) {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.bold))
                            .padding(10)
                            .background(Color.white.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                VStack(spacing: 10) {
                    Text("Unlock AI Meditation")
                        .font(.system(size: 30, weight: .semibold))
                        .multilineTextAlignment(.center)
                    Text("Try premium for deeper guidance, soothing sounds, and mindful routines.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 8)

                VStack(spacing: 12) {
                    perksCard
                    planPicker
                }

                VStack(spacing: 12) {
                    PrimaryButton(title: "START FREE TRIAL") { onClose() }

                    Button(action: onClose) {
                        Text("Maybe later")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 12)

                Text("You won't be charged today. Cancel anytime during the trial. After the trial, your chosen plan renews automatically.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
    }

    private var perksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 74, height: 74)
                    Image(systemName: "star.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Premium features")
                        .font(.headline)
                    Text("Build a calming ritual with full access.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(perks, id: \.self) { item in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(item)
                            .font(.footnote)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var planPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Choose your plan")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                ForEach(plans) { plan in
                    Button {
                        selectedPlan = plan.id
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(plan.title.uppercased())
                                        .font(.caption.weight(.semibold))
                                    if let note = plan.note {
                                        Text(note)
                                            .font(.caption2.weight(.heavy))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.black.opacity(0.06))
                                            .clipShape(Capsule())
                                    }
                                }
                                Text(plan.price)
                                    .font(.title3.weight(.semibold))
                                if let detail = plan.detail {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: selectedPlan == plan.id ? "largecircle.fill.circle" : "circle")
                                .font(.title3)
                                .foregroundStyle(.black)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.72))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(selectedPlan == plan.id ? Color.black : Color.black.opacity(0.08), lineWidth: 1.2)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct PaywallPlan: Identifiable {
    let id = UUID()
    let title: String
    let price: String
    let note: String?
    let detail: String?

    static let defaultPlans: [PaywallPlan] = [
        .init(title: "Annual", price: "$39.99", note: "BEST VALUE", detail: "Just $3.3 per month"),
        .init(title: "Monthly", price: "$6.99", note: "7-day trial", detail: "Cancel anytime"),
        .init(title: "Lifetime", price: "$79.99", note: "One-time purchase", detail: "Access forever")
    ]

    static var defaultSelection: PaywallPlan.ID {
        defaultPlans.first?.id ?? UUID()
    }
}
