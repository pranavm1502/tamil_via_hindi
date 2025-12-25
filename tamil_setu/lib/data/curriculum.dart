import '../models/lesson.dart';
import '../models/word_pair.dart';

/// The complete curriculum for the Tamil learning app.
final List<Lesson> curriculum = [
  Lesson(
    title: "1. Basics (Greet & Ask)",
    description: "Start with Namaste and basic questions.",
    words: [
      WordPair(hindi: "Namaste", tamil: "Vanakkam", pronunciation: "वनक्कम"),
      WordPair(
          hindi: "Kaise ho?",
          tamil: "Eppadi irukeenga?",
          pronunciation: "एप्पडी इरुकींगा?"),
      WordPair(
          hindi: "Main theek hoon",
          tamil: "Naan nalla irukken",
          pronunciation: "नान नल्ला इरुक्केन"),
      WordPair(hindi: "Kya?", tamil: "Enna?", pronunciation: "एन्ना?"),
      WordPair(hindi: "Naam", tamil: "Peyer", pronunciation: "पेयर"),
      WordPair(hindi: "Dhanyavaad", tamil: "Nandri", pronunciation: "नंद्रि"),
      WordPair(
          hindi: "Maaf kijiye",
          tamil: "Mannikkavum",
          pronunciation: "मन्निक्कवुम"),
      WordPair(hindi: "Haan", tamil: "Aam", pronunciation: "आम"),
      WordPair(hindi: "Nahi", tamil: "Illai", pronunciation: "इल्लै"),
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
      WordPair(hindi: "Hum", tamil: "Naangal", pronunciation: "नांगल"),
      WordPair(
          hindi: "Ye log (These people)",
          tamil: "Ivargal",
          pronunciation: "इवर्गल"),
      WordPair(
          hindi: "Wo log (Those people)",
          tamil: "Avargal",
          pronunciation: "अवर्गल"),
    ],
  ),
  Lesson(
    title: "3. Common Verbs",
    description: "Action words for daily life.",
    words: [
      WordPair(
          hindi: "Aana (Come)",
          tamil: "Vaa / Vaanga",
          pronunciation: "वा / वांगा"),
      WordPair(
          hindi: "Jaana (Go)",
          tamil: "Po / Ponga",
          pronunciation: "पो / पोंगा"),
      WordPair(hindi: "Khana (Eat)", tamil: "Saapidu", pronunciation: "सापिडु"),
      WordPair(hindi: "Peena (Drink)", tamil: "Kudi", pronunciation: "कुडि"),
      WordPair(hindi: "Sona (Sleep)", tamil: "Toongu", pronunciation: "तूंगु"),
      WordPair(
          hindi: "Uthna (Wake up)",
          tamil: "Ezhundiru",
          pronunciation: "एझुन्दिरु"),
      WordPair(hindi: "Dekhna (See)", tamil: "Paaru", pronunciation: "पारु"),
      WordPair(hindi: "Sunna (Hear)", tamil: "Kaelu", pronunciation: "काएलु"),
      WordPair(hindi: "Bolna (Speak)", tamil: "Pesu", pronunciation: "पेसु"),
    ],
  ),
  Lesson(
    title: "4. Numbers (1-10)",
    description: "Learn to count in Tamil.",
    words: [
      WordPair(hindi: "Ek (1)", tamil: "Onru", pronunciation: "ओन्रु"),
      WordPair(hindi: "Do (2)", tamil: "Irandu", pronunciation: "इरन्दु"),
      WordPair(hindi: "Teen (3)", tamil: "Moondru", pronunciation: "मून्द्रु"),
      WordPair(hindi: "Chaar (4)", tamil: "Naangu", pronunciation: "नान्गु"),
      WordPair(hindi: "Paanch (5)", tamil: "Ainthu", pronunciation: "ऐन्थु"),
      WordPair(hindi: "Chhah (6)", tamil: "Aaru", pronunciation: "आरु"),
      WordPair(hindi: "Saat (7)", tamil: "Ezhu", pronunciation: "एझु"),
      WordPair(hindi: "Aath (8)", tamil: "Ettu", pronunciation: "एट्टु"),
      WordPair(hindi: "Nau (9)", tamil: "Onpathu", pronunciation: "ओन्पथु"),
      WordPair(hindi: "Das (10)", tamil: "Pathu", pronunciation: "पथु"),
    ],
  ),
  Lesson(
    title: "5. Family Members",
    description: "Words for family relationships.",
    words: [
      WordPair(hindi: "Maa", tamil: "Amma", pronunciation: "अम्मा"),
      WordPair(hindi: "Papa", tamil: "Appa", pronunciation: "अप्पा"),
      WordPair(
          hindi: "Bhai",
          tamil: "Annan (elder) / Thambi (younger)",
          pronunciation: "अन्नन / थम्बि"),
      WordPair(
          hindi: "Behen",
          tamil: "Akka (elder) / Thangai (younger)",
          pronunciation: "अक्का / थंगै"),
      WordPair(
          hindi: "Dada/Dadi",
          tamil: "Thatha / Paatti",
          pronunciation: "थथा / पाट्टि"),
      WordPair(hindi: "Beta", tamil: "Magan", pronunciation: "मगन"),
      WordPair(hindi: "Beti", tamil: "Magal", pronunciation: "मगल"),
      WordPair(hindi: "Pati", tamil: "Kanavan", pronunciation: "कनवन"),
      WordPair(hindi: "Patni", tamil: "Manaivi", pronunciation: "मनैवि"),
    ],
  ),
  Lesson(
    title: "6. Colors",
    description: "Basic colors in Tamil.",
    words: [
      WordPair(hindi: "Laal (Red)", tamil: "Sivappu", pronunciation: "सिवप्पु"),
      WordPair(hindi: "Neela (Blue)", tamil: "Neelam", pronunciation: "नीलम"),
      WordPair(hindi: "Hara (Green)", tamil: "Pachai", pronunciation: "पचै"),
      WordPair(hindi: "Peela (Yellow)", tamil: "Manjal", pronunciation: "मंजल"),
      WordPair(
          hindi: "Kala (Black)", tamil: "Karuppu", pronunciation: "करुप्पु"),
      WordPair(
          hindi: "Safed (White)", tamil: "Vellai", pronunciation: "वेल्लै"),
      WordPair(hindi: "Gulabi (Pink)", tamil: "Panju", pronunciation: "पंजु"),
      WordPair(
          hindi: "Narangi (Orange)", tamil: "Narangi", pronunciation: "नरंगि"),
    ],
  ),
  Lesson(
    title: "7. Food & Drinks",
    description: "Common food items and beverages.",
    words: [
      WordPair(hindi: "Paani", tamil: "Thanneer", pronunciation: "थन्नीर"),
      WordPair(hindi: "Chawal", tamil: "Saadham", pronunciation: "साधम"),
      WordPair(hindi: "Roti", tamil: "Chapathi", pronunciation: "चपाथि"),
      WordPair(hindi: "Daal", tamil: "Paruppu", pronunciation: "परुप्पु"),
      WordPair(hindi: "Doodh", tamil: "Paal", pronunciation: "पाल"),
      WordPair(hindi: "Chai", tamil: "Theneer", pronunciation: "थेनीर"),
      WordPair(hindi: "Phaal", tamil: "Pazham", pronunciation: "पळम"),
      WordPair(hindi: "Sabzi", tamil: "Kari", pronunciation: "करि"),
      WordPair(hindi: "Meetha", tamil: "Inippu", pronunciation: "इनिप्पु"),
    ],
  ),
  Lesson(
    title: "8. Time & Days",
    description: "Express time and days of the week.",
    words: [
      WordPair(hindi: "Aaj", tamil: "Indru", pronunciation: "इन्द्रु"),
      WordPair(
          hindi: "Kal (Yesterday)", tamil: "Netru", pronunciation: "नेत्रु"),
      WordPair(hindi: "Kal (Tomorrow)", tamil: "Naalai", pronunciation: "नालै"),
      WordPair(hindi: "Subah", tamil: "Kaalai", pronunciation: "कालै"),
      WordPair(hindi: "Shaam", tamil: "Maalai", pronunciation: "मालै"),
      WordPair(hindi: "Raat", tamil: "Raathiri", pronunciation: "राथिरि"),
      WordPair(
          hindi: "Somvaar (Monday)", tamil: "Thingal", pronunciation: "थिंगल"),
      WordPair(
          hindi: "Shanivar (Saturday)", tamil: "Sani", pronunciation: "सनि"),
      WordPair(
          hindi: "Ravivar (Sunday)", tamil: "Gnayiru", pronunciation: "ग्नैरु"),
    ],
  ),
];
