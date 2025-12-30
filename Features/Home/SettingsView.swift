//
//  SettingsView.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 31.12.2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("userName") private var userName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $userName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Settings")
        }
    }
}
