# AI Meditation Guide 🧘‍♂️✨

AI Meditation Guide — iOS-приложение для генерации персонализированных медитаций и дыхательных практик с помощью искусственного интеллекта.  
Приложение подбирает сценарий медитации, голос, фоновый звук и длительность под конкретную цель пользователя: сон, фокус, снижение стресса и тревоги.

---

## 🎯 Purpose

Цель проекта — создать современное wellness-приложение, которое:
- генерирует уникальные медитации с помощью AI,
- помогает пользователю расслабиться, улучшить сон и концентрацию,
- сочетает дыхательные практики, аудиоплеер и аналитику прогресса,
- готово к монетизации через подписки и рекламу.

Проект реализован как **production-ready iOS MVP** с полной архитектурой и интеграциями.

---

## 📱 Core Features

### AI Meditation Generator
- Выбор цели:
  - Reduce stress
  - Improve sleep
  - Increase focus
  - Boost energy
  - Calm anxiety
- Параметры генерации:
  - Duration (5 / 10 / 15 min)
  - Voice style (Soft / Neutral / Deep)
  - Background sound (Nature / Ambient / Rain / None)
- Генерация:
  - AI-сценарий медитации
  - Обложка
  - Озвучка через AI TTS

### Meditation Player
- Воспроизведение AI-голоса
- Фоновый ambient-звук
- Раздельная регулировка громкости (voice / background)
- Timeline + seek
- Finish early с подтверждением
- Save to History
- Таймер оставшегося времени (Remaining Time)

### Breathing Exercises
- Mood check-in:
  - Calm
  - Neutral
  - Stressed
  - Anxious
- Длительность:
  - 1 / 3 / 5 min
- Анимированная дыхательная логика:
  - Inhale → Hold → Exhale
- Локализованные инструкции

### History & Progress
- История медитаций и дыхательных упражнений
- Повторное воспроизведение
- Удаление записей
- Статистика:
  - Total minutes meditated
  - Daily streak
  - Weekly progress

---

## 🏗️ Architecture

- **SwiftUI**
- **SwiftData**
- **MVVM**
- **Feature-based structure**
- **Async / Await**
- **Dependency isolation**
- **Config via `.xcconfig`**
- **Secrets excluded from Git**

---

## 🌍 Localization

- English
- Russian
- Полная локализация UI
- Отсутствие `rawValue` в интерфейсе
- Централизованный `Localizable.strings`

---

## 🔊 Audio Stack

- `AVFoundation`
- AI TTS (OpenAI)
- Voice & background mixing
- Smart loading & seeking
- Local file persistence

---

## 🤖 AI Integration

### OpenAI
- Chat Completions (JSON-response)
- Генерация:
  - title
  - summary
  - meditation script
- Image generation для обложек
- Text-to-Speech (MP3)

---

## 💳 Monetization

### Subscriptions (AppHud)
- Weekly / Monthly / Yearly
- Product IDs:
  - `sonicforge_weekly`
  - `sonicforge_monthly`
  - `sonicforge_yearly`
- Paywall ID:
  - `main_paywall`
- Restore purchases
- Subscription status listener

### Ads
- AdMob Rewarded Ads
- Просмотр рекламы → запуск медитации

---

## 📊 Analytics & Attribution

### Integrated SDKs
- **Firebase Analytics**
- **AppsFlyer**
- **Yandex AppMetrica**
- **AppHud Attribution**

### App Tracking Transparency
- Полная поддержка ATT (iOS)
- Обработка всех статусов
- Передача статуса в AppsFlyer

---

## 🏪 App Store Information

### App Metadata
- **App Name:** AI Meditation Guide
- **Subtitle:** Personalized AI-powered meditation & breathing
- **Category:** Health & Fitness
- **Primary Language:** English
- **Additional Language:** Russian
- **Age Rating:** 4+

---

## 🔐 App Privacy

### Collected Data
- Identifiers (IDFA — с разрешения пользователя)
- Usage Data (analytics)
- Purchases (subscriptions)

### Data Usage
- Analytics (Firebase, AppsFlyer, AppMetrica)
- Advertising (AdMob)
- App Functionality (AppHud)

### Tracking
- **Tracking:** Yes
- Реализовано через `AppTrackingTransparency`

### Data Linked to User
- **Yes**
- Используется для аналитики и рекламы

> Приложение соответствует требованиям App Store Review Guidelines.

---

## 🧪 Project Status

### ✅ Completed (MVP Core)
- Meditation generator
- Breathing exercises
- Custom audio player
- History & progress
- Localization
- Analytics & attribution
- Monetization foundation
- Config & security setup
- GitHub repository

### 🔜 Planned
- Daily routine generation
- Favorites
- Background audio smart looping
- Offline handling
- Real StoreKit subscriptions
- App icon & launch screen
- TestFlight release

---

## 🚀 Build & Run

```bash
pod install
open AIMeditationGuide.xcworkspace
```

•	Xcode 15+
•	iOS 16+
•	Release configuration uses .xcconfig

⸻

📌 Notes

This project is production-oriented and ready for:
•	TestFlight
•	App Store submission
•	Further scaling

⸻

Author: Vladislav
Platform: iOS
Stack: SwiftUI
