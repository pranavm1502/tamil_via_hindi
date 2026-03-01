# Tamil Setu (तमिल सेतु)

<div align="center">

**A Hindi-to-Tamil language learning application built with Flutter**


</div>

## 📱 About

Tamil Setu is a Flutter application designed to help Hindi speakers learn Tamil through an interactive, engaging learning experience. The app uses a structured curriculum with topic-based lessons, audio pronunciation support, and interactive quizzes to reinforce learning.

## ✨ Features

- **📚 Dynamic Curriculum** - Over 30 lessons loaded from a central JSON file, covering everything from survival basics to complex sentences.
- **🔊 Audio Support** - Native audio playback for every word and phrase to ensure proper pronunciation.
- **🎯 Interactive Quizzes** - Test your knowledge with multiple-choice and flashcard-style quizzes at the end of each lesson.
- **🧠 Spaced Repetition System (SRS)** - A smart review system to help you remember words more effectively over time.
- **🏆 Checkpoint Quizzes** - Unlock new sets of lessons by passing checkpoint quizzes.
- **📊 Progress Tracking** - Keep track of completed lessons and quiz scores.
- **☁️ Cloud Sync** - Authenticate with Google Sign-In to sync your progress across devices.
- **🔥 Streaks & Leaderboards** - Maintain learning streaks and compare progress.
- **🎯 Daily Goals** - Set a daily review target and track progress toward it.
- **🔔 Reminders** - Optional daily review notifications at your preferred time.
- **🎨 Peacock Theme** - A beautiful, modern UI inspired by the colors of a peacock, with both light and dark modes.
- **💾 Offline First** - All lesson content and progress are saved locally, so you can learn even without an internet connection.

## 📸 Screenshots

*To update Play Store screenshots from a real Android emulator/device:*
```bash
cd tamil_setu
flutter test integration_test/screenshots_test.dart -d <android-device-id>
```
*Screenshots are saved by the Flutter tool under build/ output. Copy them into
`tamil_setu/test/metadata/en-US/images` as needed for Play Store assets.*

*For golden widget screenshots (UI regression):*
```bash
./update_golden_screenshots.sh
```
*Play Store screenshots are saved under `tamil_setu/test/metadata/en-US/images`.*


## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode (for mobile development)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/pmundada/tamil_via_hindi.git
   cd tamil_via_hindi/tamil_setu
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

#### Android APK
```bash
flutter build apk --release
```
The APK will be available at `build/app/outputs/flutter-apk/app-release.apk`

#### iOS
```bash
flutter build ios --release
```

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point and configuration
├── theme.dart                # App theme and styling (PeacockTheme)
├── firebase_options.dart     # Firebase configuration
├── data/                     # Data loading logic
│   └── curriculum.dart      # Loads lesson and quiz content from JSON
├── models/                   # Data models
│   ├── lesson.dart          # Lesson model
│   ├── word_pair.dart       # Word pair model for lessons
│   ├── checkpoint.dart      # Checkpoint quiz model
│   └── review_card.dart     # Review card model for SRS
├── providers/                # State management using Provider
│   ├── content_provider.dart  # Provides lesson and quiz content
│   ├── progress_provider.dart # Manages user progress
│   ├── review_provider.dart   # Manages review cards for SRS
│   └── theme_provider.dart    # Manages app theme (light/dark)
├── screens/                  # UI screens
│   ├── dashboard_screen.dart    # Main screen with lesson list
│   ├── lesson_screen.dart       # Screen for individual lessons
│   ├── quiz_view.dart           # View for lesson quizzes
│   ├── checkpoint_quiz_screen.dart # Screen for checkpoint quizzes
│   ├── multiple_choice_quiz.dart # Multiple choice quiz widget
│   └── review_screen.dart       # Screen for spaced repetition review
├── services/                 # Business logic and services
│   ├── auth_service.dart        # Authentication service (Google Sign-In)
│   ├── progress_service.dart    # Service for saving/loading progress locally
│   ├── review_storage_service.dart # Local storage for review cards
│   ├── srs_service.dart         # Spaced Repetition System logic
│   ├── sync_service.dart        # Service for syncing data with Cloud Firestore
│   └── tts_service.dart         # Text-to-Speech service
└── widgets/                    # Reusable UI widgets
    ├── peacock_mascot.dart    # Peacock mascot widget
    └── word_card.dart         # Card widget for displaying words
```

## 📚 Curriculum

The app currently includes over 30 lessons with hundreds of word pairs, loaded dynamically from `assets/data/master_content.json`. The curriculum covers a wide range of topics, including:

- Survival Basics
- Pronouns
- Verbs & Tenses
- Questions
- Numbers & Time
- Family, Food & Shopping
- ...and much more!

## 🔧 Configuration

### Adding New Lessons

1. Edit `assets/data/master_content.json`
2. Add a new lesson object to the JSON array following the existing structure.

### Customizing Theme

Edit `lib/theme.dart` to modify the `PeacockTheme` class. You can change colors for both light and dark themes.
```dart
class PeacockTheme {
  // Peacock-inspired color palette
  static const Color peacockBlue = Color(0xFF005DAA);
  static const Color peacockGreen = Color(0xFF00A896);
  // ... more colors
}
```

## 🧪 Testing

### Run all tests
```bash
flutter test
```

### Run with coverage
```bash
flutter test --coverage
```

### Testing Notes

- Widget and provider tests use Firebase/Auth mocks and Fake Firestore instances.
- If you add new Firebase-dependent tests, mock initialization is required.

## 🔐 Firebase & Sign-In

- Firebase config is generated in [lib/firebase_options.dart](lib/firebase_options.dart).
- Android requires [android/app/google-services.json](android/app/google-services.json).
- iOS requires the GoogleService-Info.plist in [ios/Runner](ios/Runner).
- Sign-in flows are centralized in [lib/services/auth_service.dart](lib/services/auth_service.dart).

## 🔔 Notifications

- Daily reminders are scheduled via [lib/services/notification_service.dart](lib/services/notification_service.dart).
- The app requests notification permission at scheduling time and uses local time zones.

## 🧭 Architecture Notes

- Providers in [lib/providers](lib/providers) own state and delegate persistence to services.
- Firestore sync lives in [lib/services/sync_service.dart](lib/services/sync_service.dart) and is injected in tests.
- Review logic is in [lib/services/srs_service.dart](lib/services/srs_service.dart) and surfaced by [lib/providers/review_provider.dart](lib/providers/review_provider.dart).

## 🔄 CI/CD

The project uses GitHub Actions for continuous integration and release:

- **Build & Release** - Automatically builds and releases APK on push to main branch.

See `.github/workflows/build_and_release.yml` for configuration.

## 🛠️ Technologies Used

- **Flutter** - Cross-platform UI framework
- **Provider** - State management
- **Firebase** - Backend services (Authentication, Firestore)
- **Google Sign-In** - For user authentication
- **SharedPreferences** - For local data persistence
- **audioplayers** - For audio playback
- **confetti** - For celebrations
- **Material Design 3** - Modern UI components

## 📖 Learning Approach

Tamil Setu uses a proven language learning methodology:

1. **Visual Learning** - See Hindi, Tamil, and phonetic pronunciation together
2. **Audio Reinforcement** - Hear native pronunciation via TTS
3. **Active Recall** - Test knowledge with interactive quizzes
4. **Progress Tracking** - Build motivation through visible progress
5. **Spaced Repetition** - Shuffle quiz questions for better retention

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Add Content** - Expand the curriculum with new lessons and words
2. **Improve Translations** - Verify accuracy of Tamil translations
3. **Add Features** - Implement new learning modes or features
4. **Fix Bugs** - Report and fix issues
5. **Improve Documentation** - Enhance README and code comments

### Contribution Guidelines

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 Roadmap

- [ ] Additional quiz modes (multiple choice, listening comprehension)
- [ ] Spaced repetition algorithm (SM-2)
- [ ] Dark mode support
- [ ] More lessons (advanced grammar, conversation practice)
- [ ] Sentence construction exercises
- [ ] Audio recording for pronunciation practice
- [ ] Social features (leaderboards, sharing progress)
- [ ] Cloud sync for cross-device progress

## 📄 License

This project is open source and available under the MIT License.

## 👥 Authors

- [Pranav](https://github.com/pranavm1502)
- [Vivek](https://github.com/vivekkr1809)

## 🙏 Acknowledgments

- Tamil language experts for content validation
- Flutter community for excellent documentation
- Open source contributors

## 📞 Support

If you have questions or need help:

- Open an issue on GitHub
- Check existing documentation
- Review closed issues for similar problems

## 🌟 Show Your Support

Give a ⭐️ if this project helped you learn Tamil!

---

**Made with ❤️ for Hindi speakers learning Tamil**
