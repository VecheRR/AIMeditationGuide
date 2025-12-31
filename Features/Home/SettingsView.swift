//
//  SettingsView.swift
//  AIMeditationGuide
//
//  Created by  Vladislav on 31.12.2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("appLanguage") private var appLanguage: String = "system" // "system" | "en" | "ru"

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $userName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }

                Section("Language") {
                    Picker("Language", selection: $appLanguage) {
                        Text("System").tag("system")
                        Text("English").tag("en")
                        Text("Русский").tag("ru")
                    }
                    .pickerStyle(.menu) // можно убрать, будет стандартный
                }
            }
            .navigationTitle("Settings")
        }
    }
}
