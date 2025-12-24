# Tamil Setu (तमिल सेतु)

<div align="center">

**A Hindi-to-Tamil language learning application built with Flutter**

[![Build APK](https://github.com/vivekkr1809/tamil_via_hindi/actions/workflows/build_apk.yml/badge.svg)](https://github.com/vivekkr1809/tamil_via_hindi/actions/workflows/build_apk.yml)

</div>

## 📱 About

Tamil Setu is a Flutter application designed to help Hindi speakers learn Tamil through an interactive, engaging learning experience. The app uses a structured curriculum with topic-based lessons, audio pronunciation support, and interactive quizzes to reinforce learning.

## ✨ Features

- **📚 Topic-based Learning** - 8 comprehensive lessons covering basics, pronouns, verbs, numbers, family, colors, food, and time
- **🔊 Audio Support (TTS)** - Native Text-to-Speech for proper Tamil pronunciation
- **🎯 Interactive Quizzes** - Test your knowledge with flashcard-style quizzes
- **📊 Progress Tracking** - Track completed lessons and quiz scores
- **🏆 Achievement System** - Visual progress indicators and completion badges
- **🎨 Clean UI** - Modern Material Design 3 interface
- **💾 Offline First** - All content available offline, progress saved locally

## 📸 Screenshots

*(Screenshots would go here in production)*

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode (for mobile development)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/vivekkr1809/tamil_via_hindi.git
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
├── models/                   # Data models
│   ├── lesson.dart          # Lesson model
│   └── word_pair.dart       # Word pair model
├── data/                     # Static data
│   └── curriculum.dart      # Lesson content
├── screens/                  # UI screens
│   ├── dashboard_screen.dart # Main lesson list
│   ├── lesson_screen.dart   # Lesson details with tabs
│   └── quiz_view.dart       # Quiz interface
├── services/                 # Business logic services
│   ├── tts_service.dart     # Text-to-speech service
│   └── progress_service.dart # Progress tracking
└── providers/                # State management
    └── progress_provider.dart # Progress state provider
```

## 📚 Curriculum

The app currently includes 8 lessons with 60+ word pairs:

1. **Basics** - Greetings and basic questions (9 words)
2. **Pronouns** - Personal and demonstrative pronouns (8 words)
3. **Common Verbs** - Essential daily actions (9 words)
4. **Numbers** - Counting from 1-10 (10 words)
5. **Family Members** - Family relationships (9 words)
6. **Colors** - Basic colors (8 words)
7. **Food & Drinks** - Common food items (9 words)
8. **Time & Days** - Time expressions and days (9 words)

## 🔧 Configuration

### Adding New Lessons

1. Edit `lib/data/curriculum.dart`
2. Add a new `Lesson` object to the `curriculum` list:
   ```dart
   Lesson(
     title: "9. Your Topic",
     description: "Description of the topic",
     words: [
       WordPair(
         hindi: "Hindi word",
         tamil: "Tamil word",
         pronunciation: "Devanagari pronunciation",
       ),
       // Add more word pairs...
     ],
   ),
   ```

### Customizing Theme

Edit `lib/main.dart` to modify colors and theme:
```dart
theme: ThemeData(
  primarySwatch: Colors.orange,  // Change primary color
  scaffoldBackgroundColor: Colors.orange[50],
  useMaterial3: true,
),
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

### Widget tests
The app includes widget tests for:
- App launch and initialization
- Dashboard lesson display
- Navigation to lesson screens

## 🔄 CI/CD

The project uses GitHub Actions for continuous integration:

- **Build APK** - Automatically builds release APK on push to main branch
- Artifacts are uploaded and available for download

See `.github/workflows/build_apk.yml` for configuration.

## 🛠️ Technologies Used

- **Flutter** - Cross-platform UI framework
- **Provider** - State management
- **SharedPreferences** - Local data persistence
- **flutter_tts** - Text-to-Speech functionality
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

- [vivekkr1809](https://github.com/vivekkr1809)

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
