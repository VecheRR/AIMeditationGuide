//
//  MeditationPlayerView.swift
//  AIMeditationGuide
//
//  Created by ChatGPT on 2025-06-03.
//

import SwiftUI
import SwiftData

struct MeditationPlayerView: View {
    let session: MeditationSession

    @State private var background: GenBackground

    init(session: MeditationSession) {
        self.session = session
        _background = State(initialValue: session.background)
    }

    var body: some View {
        PlayerView(
            title: session.title,
            summary: session.summary,
            durationMinutes: session.durationMinutes,
            voiceURL: session.voiceURL,
            background: $background
        )
    }
}
