import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const TamilSetuApp());
}

// --- DATA MODELS ---
class Lesson {
  final String title;
  final String description;
  final List<WordPair> words;

  Lesson({required this.title, required this.description, required this.words});
}

class WordPair {
  final String hindi;
  final String tamil;
  final String pronunciation;

  WordPair({
    required this.hindi,
    required this.tamil,
    required this.pronunciation,
  });
}

// --- MOCK CURRICULUM ---
final List<Lesson> curriculum = [
  Lesson(
    title: "1. Basics (Greet & Ask)",
    description: "Start with Namaste and basic questions.",
    words: [
      WordPair(hindi: "Namaste", tamil: "Vanakkam", pronunciation: "वनक्कम"),
      WordPair(hindi: "Kaise ho?", tamil: "Eppadi irukeenga?", pronunciation: "एप्पडी इरुकींगा?"),
      WordPair(hindi: "Main theek hoon", tamil: "Naan nalla irukken", pronunciation: "नान नल्ला इरुक्केन"),
      WordPair(hindi: "Kya?", tamil: "Enna?", pronunciation: "एन्ना?"),
      WordPair(hindi: "Naam", tamil: "Peyer", pronunciation: "पेयर"),
    ],
  ),
  Lesson(
    title: "2. Pronouns (Me & You)",
    description: "Referencing yourself and others.",
    words: [
      WordPair(hindi: "Main", tamil: "Naan", pronunciation: "नान"),
      WordPair(hindi: "Tum (Informal)", tamil: "Nee", pronunciation: "नी"),
      WordPair(hindi: "Aap (Formal)", tamil: "Neengal", pronunciation: "नींगल"),
      WordPair(hindi: "Yeh (This person)", tamil: "Ivar", pronunciation: "इवर"),
      WordPair(hindi: "Woh (That person)", tamil: "Avar", pronunciation: "अवर"),
    ],
  ),
  Lesson(
    title: "3. Common Verbs",
    description: "Action words for daily life.",
    words: [
      WordPair(hindi: "Aana (Come)", tamil: "Vaa / Vaanga", pronunciation: "वा / वांगा"),
      WordPair(hindi: "Jaana (Go)", tamil: "Po / Ponga", pronunciation: "पो / पोंगा"),
      WordPair(hindi: "Khana (Eat)", tamil: "Saapidu", pronunciation: "सापिडु"),
      WordPair(hindi: "Peena (Drink)", tamil: "Kudi", pronunciation: "कुडि"),
    ],
  ),
];

// --- MAIN WIDGET ---
class TamilSetuApp extends StatelessWidget {
  const TamilSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tamil Setu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.orange[50],
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

// --- DASHBOARD ---
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tamil Setu (हिंदी ➡️ தமிழ்)"),
        centerTitle: true,
        elevation: 2,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: curriculum.length,
        itemBuilder: (context, index) {
          final lesson = curriculum[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Colors.orange,
                child: Text("${index + 1}", style: const TextStyle(color: Colors.white)),
              ),
              title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text(lesson.description),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LessonScreen(lesson: lesson)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// --- LESSON SCREEN (WITH AUDIO) ---
class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("ta-IN");
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.book), text: "Learn"),
            Tab(icon: Icon(Icons.quiz), text: "Quiz"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLearnTab(),
          _buildQuizTab(),
        ],
      ),
    );
  }

  Widget _buildLearnTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.lesson.words.length,
      itemBuilder: (context, index) {
        final pair = widget.lesson.words[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pair.hindi, style: const TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(pair.tamil, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                    Text("(${pair.pronunciation})", style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up, size: 30, color: Colors.orange),
                  onPressed: () => _speak(pair.tamil),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizTab() {
    return QuizView(words: widget.lesson.words);
  }
}

// --- QUIZ LOGIC ---
class QuizView extends StatefulWidget {
  final List<WordPair> words;
  const QuizView({super.key, required this.words});

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  int currentIndex = 0;
  int score = 0;
  bool showAnswer = false;

  void _nextCard(bool knewIt) {
    if (knewIt) score++;
    setState(() {
      if (currentIndex < widget.words.length - 1) {
        currentIndex++;
        showAnswer = false;
      } else {
        _showResultDialog();
      }
    });
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Quiz Complete!"),
        content: Text("You scored $score out of ${widget.words.length}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("Finish"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentWord = widget.words[currentIndex];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Question ${currentIndex + 1}/${widget.words.length}", textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              height: 200,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Translate this Hindi word:", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(currentWord.hindi, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const Divider(height: 30),
                  if (showAnswer) ...[
                    Text(currentWord.tamil, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange)),
                    Text(currentWord.pronunciation, style: const TextStyle(fontSize: 20, color: Colors.blueGrey)),
                  ] else
                    const Text("?", style: TextStyle(fontSize: 40, color: Colors.orange)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          if (!showAnswer)
            ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              onPressed: () => setState(() => showAnswer = true),
              child: const Text("Show Answer", style: TextStyle(fontSize: 18)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                    onPressed: () => _nextCard(false),
                    child: const Text("Wrong"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                    onPressed: () => _nextCard(true),
                    child: const Text("Correct"),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
