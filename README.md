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
- [x] Breathing exercise flow
  - [x] Setup screens (mood, duration)
  - [x] Localized mood & duration pickers (EN / RU)
  - [x] Animated breathing session (inhale / hold / exhale loop)
  - [x] Proper breathing timing logic (phase-based)
  - [x] Localized breathing instructions & phase titles
- [x] SwiftUI project structure (App / Core / Features)
- [x] Navigation architecture (RootView, TabView, sheet & fullScreenCover flows)
- [x] Onboarding flow (fully localized)
- [x] Paywall screen (UI complete, StoreKit stub)
- [x] Home screen layout
  - Generator CTA
  - Breathing shortcut
  - Routine entry point
  - Latest session CTA
- [x] Meditation generator flow
  - Goal selection
  - Duration selection
  - Voice style selection
  - Background sound selection
  - Fully localized UI
- [x] OpenAI integration (Chat Completions)
- [x] AI meditation script generation
- [x] OpenAI TTS voice synthesis
- [x] Audio player (AVFoundation)
  - Voice playback
  - Background ambient sounds
  - Separate volume controls (voice / background)
  - Timeline & seek
- [x] Player UI (custom SwiftUI player)
- [x] SwiftData integration
- [x] Meditation & breathing history storage
- [x] History list UI (meditations + breathing logs)
- [x] History → Player playback
- [x] Localization system
  - English / Russian support
  - Centralized `Localizable.strings`
  - No `rawValue` usage in UI
- [x] Config management via `.xcconfig`
- [x] Secrets excluded from Git
- [x] Project pushed to GitHub

---

### 🟡 In Progress
- [ ] Design polish (spacing, typography consistency)
- [ ] Background picker UX improvements
- [ ] Background audio duration handling when voice is shorter

---

### 🔜 TODO (Next milestones)
- [ ] Backgrounds: smart looping & fade-out logic
- [ ] Error handling & offline states
- [ ] Real StoreKit subscriptions
- [ ] Daily routine generation (AI-based)
- [ ] Routine progress tracking
- [ ] Persist generated voice files with sessions
- [ ] Favorites / liked meditations
- [ ] Replace placeholder covers with generated or static visuals
- [ ] Improve AI prompt quality
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
