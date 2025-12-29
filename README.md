# AI Meditation Guide 🧘‍♂️✨

iOS application built with SwiftUI that generates personalized guided meditations using AI.

## Features
- AI-generated meditation scripts
- Voice synthesis (TTS)
- Background ambient sounds
- Meditation player with separate voice/background volume
- Breathing exercises
- Meditation history (SwiftData)
- Onboarding & Paywall flow

## Tech Stack
- SwiftUI
- SwiftData
- AVFoundation
- OpenAI API (Chat Completions + TTS)
- MVVM architecture
- xcconfig-based configuration

## Project Structure
```text
App/            – App entry point & navigation
Core/           – Networking, audio, storage, UI components
Features/       – Home, Generator, Player, Breathing, History
Config/         – Build configs (Secrets excluded from Git)
```

## Setup
```code
1. Clone repository
2. Create `Config/Secrets.xcconfig`
3. Add your OpenAI API key
4. Build & Run
```

## Status
🚧 MVP in active development
