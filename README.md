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

## Project Status ✅🛠️

### ✅ Completed (MVP core)
- [x] SwiftUI project structure (App / Core / Features)
- [x] Navigation architecture (RootView, TabView, fullScreenCover flows)
- [x] Onboarding flow
- [x] Paywall screen (stub logic with AppStorage)
- [x] Home screen layout
- [x] Meditation generator flow
  - [x] Goal selection
  - [x] Duration selection
  - [x] Voice style selection
  - [x] Background sound selection
- [x] OpenAI integration (Chat Completions)
- [x] AI meditation script generation
- [x] OpenAI TTS voice synthesis
- [x] Audio player (AVFoundation)
  - [x] Voice playback
  - [x] Background ambient sounds
  - [x] Separate volume controls (voice / background)
  - [x] Timeline & seek
- [x] Player UI (custom SwiftUI player)
- [x] SwiftData integration
- [x] Meditation history storage
- [x] History list UI
- [x] Config management via `.xcconfig`
- [x] Secrets excluded from Git
- [x] Project pushed to GitHub

---

### 🟡 In Progress
- [ ] Breathing exercise flow
  - [x] Setup screens (mood, duration)
  - [ ] Animated breathing session (inhale / exhale loop)
  - [ ] Proper breathing timing logic
- [ ] Design polish (spacing, typography consistency)
- [ ] Background picker UX improvements
- [ ] Proper duration handling (fill remaining time with background sound)

---

### 🔜 TODO (Next milestones)
- [ ] Breathing animation synced with inhale/exhale duration
- [ ] Save breathing sessions to history
- [ ] Play meditation from History (tap → Player)
- [ ] Persist generated voice files with sessions
- [ ] Favorites / liked meditations
- [ ] Daily routine generation (AI-based)
- [ ] Routine progress tracking
- [ ] Replace placeholder covers with generated or static visuals
- [ ] Improve AI prompt quality (longer, more structured meditations)
- [ ] Error handling & offline states
- [ ] Paywall logic with real subscription (StoreKit)
- [ ] App icon & launch screen
- [ ] Accessibility (Dynamic Type, VoiceOver)
- [ ] TestFlight build
- [ ] App Store preparation

---

### 🧪 Optional / Nice to Have
- [ ] Local caching of AI responses
- [ ] Downloadable background sound packs
- [ ] Multiple voice options
- [ ] Dark mode fine-tuning
- [ ] Analytics events
