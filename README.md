# 🧱 Deadlock — Sliding-Block Puzzle Game

Deadlock is a premium, high-performance, and beautifully designed sliding-block puzzle game built with Flutter. Inspired by classic block slide mechanics, it features a custom Xorshift32 PRNG-driven deterministic board generator, dynamic solver algorithms, and lofi arcade-style custom synthesized sound effects and vibration feedback.

---

## ✨ Features

- **🎮 500 Monotonically Sorted Levels**: Every level is guaranteed to be equal or harder than the previous one. Difficulty curves scale seamlessly from beginner to legendary.
- **⚡ Performance Optimized Canvas**: Custom-designed rendering tree built entirely inside specialized `AnimatedBuilder` repaint boundaries to achieve a buttery-smooth 60/120 FPS on all screens.
- **🔊 Elegant Custom Synthesized Audio**: Built-in retro-modern synthesized WAV sound effects (crisp click tap, warm sliding whoosh, and luxurious C-Major7 chord chimes) with setting-toggles.
- **📳 Immersive Haptics**: Realistic vibration responses mapped directly to player touch states, block collisions, and puzzle wins.
- **🌍 Premium Segmented Language Selector**: Seamless localized text (both Turkish and English) switching in settings with a gorgeous 3D segmented pill button.
- **📱 Three Game Modes**:
  - **Standard Levels**: Work through the curated sequence of 500 levels.
  - **Daily Mode**: A new, extra challenging, and calendar-synced puzzle generated daily with streak trackers.
  - **Sprint (Koşu) Mode**: Race against a 45-second clock, gaining +6 seconds with each solved puzzle as the difficulty scales dynamically.
  - **Zen Mode**: Relaxing infinite level progression with no time constraints.

---

## 🛠️ Tech Stack & Architecture

- **Core**: Flutter, Dart.
- **State Management**: Clean `ChangeNotifier` controllers (`GameController`, `ProgressController`, `SprintController`) paired with reactive listeners.
- **Domain Logic**: 
  - `solver.dart`: Optimal BFS solver utilizing position-only key hashing for memory-efficient visited states.
  - `generator.dart`: Deterministic board generator yielding solvable, seed-dependent puzzle layouts.
  - `difficulty.dart`: Difficulty progression matrices defining block constraints and move bands.
- **Local Storage**: Synchronous start-up via `SharedPreferences` wrapper to prevent data loss.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.0.0 or higher recommended)
- Android SDK / Xcode (for mobile builds)

### Installation
1. Clone this repository:
   ```bash
   git clone https://github.com/emir-canswe/deatlock.git
   cd deatlock
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Generate sound assets:
   ```bash
   dart run scripts/generate_sounds.dart
   ```
4. Run the project in development mode:
   ```bash
   flutter run
   ```

---

## 📦 Production Builds

### Build Web App
To build the PWA web app:
```bash
flutter build web --release --base-href /deadlock/
```

### Build Android APKs
To generate split APKs optimized for target CPU architectures:
```bash
flutter build apk --release --split-per-abi
```

---

## 📁 Project Structure

```
lib/
├── core/           # Game theme, palette, motion curves, haptics wrapper, and audio player
├── data/           # Repositories, Daily state stores, and local storage (shared preferences)
├── domain/         # Game logic, Move, BoardState, PRNG, generator, and BFS Solver algorithms
├── state/          # UI controllers and change notifies
└── ui/             # Screen pages and reusable custom 3D widgets (BoardView, top bars, ChunkyButtons)
```

---

## 📄 License
This project is private and proprietary. All rights reserved.
