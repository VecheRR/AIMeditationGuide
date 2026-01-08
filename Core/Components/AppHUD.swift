//
//  AppHUD.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 07.01.2026.
//

import SwiftUI
import Combine

@MainActor
final class HUDCenter: ObservableObject {
    struct Toast: Identifiable, Equatable {
        enum Style { case success, error, info }
        let id = UUID()
        let title: String
        let message: String?
        let style: Style
        let duration: TimeInterval
    }

    @Published var isLoading: Bool = false
    @Published var loadingTitle: String? = nil
    @Published var toast: Toast? = nil

    func showLoading(_ title: String? = nil) {
        loadingTitle = title
        isLoading = true
    }

    func hideLoading() {
        isLoading = false
        loadingTitle = nil
    }

    func showToast(
        _ title: String,
        message: String? = nil,
        style: Toast.Style = .info,
        duration: TimeInterval = 2.0
    ) {
        toast = Toast(title: title, message: message, style: style, duration: duration)
    }
}

struct AppHUDOverlay: View {
    @EnvironmentObject private var hud: HUDCenter

    var body: some View {
        ZStack {
            if hud.isLoading {
                loadingView
                    .transition(.opacity)
            }

            if let toast = hud.toast {
                toastView(toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                            withAnimation(.easeInOut) { hud.toast = nil }
                        }
                    }
            }
        }
        .animation(.easeInOut, value: hud.isLoading)
        .animation(.easeInOut, value: hud.toast)
        .allowsHitTesting(hud.isLoading) // лоадер блокирует нажатия
    }

    private var loadingView: some View {
        ZStack {
            Color.black.opacity(0.22).ignoresSafeArea()

            VStack(spacing: 10) {
                ProgressView()
                if let t = hud.loadingTitle {
                    Text(t)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func toastView(_ toast: HUDCenter.Toast) -> some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: icon(for: toast.style))
                    .foregroundStyle(color(for: toast.style))

                VStack(alignment: .leading, spacing: 2) {
                    Text(toast.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    if let msg = toast.message, !msg.isEmpty {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()
        }
        .ignoresSafeArea()
    }

    private func icon(for style: HUDCenter.Toast.Style) -> String {
        switch style {
        case .success: return "checkmark.circle.fill"
        case .error:   return "exclamationmark.triangle.fill"
        case .info:    return "info.circle.fill"
        }
    }

    private func color(for style: HUDCenter.Toast.Style) -> Color {
        switch style {
        case .success: return .green
        case .error:   return .yellow
        case .info:    return .blue
        }
    }
}
