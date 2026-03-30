#!/usr/bin/env python3
"""
One-time script to add 'english' field to every word in master_content.json.
This field is used by generate_images.py to build English prompts for Stable
Diffusion (which cannot understand Devanagari text).

Usage:
    python scripts/add_english_to_content.py [--dry-run]
"""

import argparse
import json
import re
from pathlib import Path

APP_ROOT = Path(__file__).resolve().parent.parent
CONTENT_JSON = APP_ROOT / "assets" / "data" / "master_content.json"

# ── Hindi → English visual-concept mapping ────────────────────────────────────
# Each value describes the *visual concept* for image generation, not a literal
# translation. Phrases map to a scene or object that Stable Diffusion can render.
HINDI_TO_ENGLISH = {
    # L1: Survival Basics
    "नमस्ते / हेलो": "greeting hello namaste",
    "हाँ": "yes thumbs up",
    "नहीं": "no shaking head",
    "ठीक है (Okay)": "okay",
    "मुझे नहीं पता": "confused person shrugging",
    "कोई बात नहीं": "no problem cheerful wave",
    "जल्दी": "fast running quickly",
    "धीरे": "slow calm pace",
    "रुको": "stop hand gesture",
    "चलो / चलें": "let us go walking together",
    # L2: Pronouns
    "मैं": "person pointing at self",
    "तुम (Casual)": "pointing at you casually",
    "आप (Respect)": "respectful greeting",
    "हम (सब साथ में)": "group of people together inclusive",
    "हम (सामने वाले को छोड़कर)": "small group exclusive",
    "यह (This person/thing)": "pointing here nearby",
    "वह (That person/thing)": "pointing there distant",
    # L3: Important Verbs (Command)
    "आओ (Come)": "come here beckoning gesture",
    "जाओ (Go)": "go away walking direction",
    "खाओ (Eat)": "eating food",
    "पीओ (Drink)": "drinking water",
    "देखो (Look)": "looking watching eyes",
    "बैठो (Sit)": "sitting down on chair",
    "सो जाओ (Sleep)": "sleeping in bed",
    "दो (Give)": "giving handing over",
    # L4: Common Questions
    "क्या?": "question mark what",
    "कहाँ?": "where searching looking around",
    "कब?": "when clock time",
    "क्यों?": "why curious thinking",
    "कौन?": "who person silhouette question",
    "कितना? (Money)": "how much money coins",
    "कैसे?": "how method thinking",
    "खाना खाया? (Ate?)": "have you eaten meal plate",
    # L5: Connecting Words
    "यहाँ": "here this place arrow down",
    "वहाँ": "there that place arrow away",
    "अभी": "now present moment clock",
    "बाद में": "later alarm clock future",
    "लेकिन": "but contrast two sides",
    "और": "and plus adding together",
    # L6: The Magic '-ku' (To/For)
    "मुझे (To me)": "to me pointing at self",
    "तुम्हें (To you)": "to you pointing at other",
    "आपको (To you - Respect)": "to you respectfully",
    "घर को / घर जाना है": "heading home house direction",
    "ऑफिस को": "heading to office building",
    "दुकान को": "heading to shop store",
    "बैंगलोर को": "heading to city travel",
    # L7: The Magic '-la' (In/At/By)
    "घर में (In the house)": "inside a house home interior",
    "रास्ते में (On the way)": "on the road path",
    "हाथ में": "in hand holding something",
    "गाड़ी में (In the car/bike)": "inside a car vehicle",
    "बैंगलोर में": "in the city Bangalore",
    "हिंदी में": "in Hindi language text",
    # L8: Past Tense
    "मैं गया (I went)": "person walking away departed",
    "मैं आया (I came)": "person arriving coming",
    "मैंने देखा (I saw)": "person looking observed",
    "मैंने ख़रीदा (I bought)": "shopping bags purchased",
    "उसने दिया (He/She gave)": "handing gift giving",
    "खत्म हो गया (Finished)": "finished completed checkmark",
    # L9: Present Continuous
    "मैं जा रहा हूँ": "person currently walking going",
    "मैं आ रहा हूँ": "person on the way coming",
    "बारिश हो रही है": "rain falling from clouds",
    "समझ आ रहा है?": "understanding lightbulb moment",
    "भूख लग रही है": "hungry person empty stomach",
    "क्या कर रहे हो?": "what are you doing activities",
    # L10: Negation
    "नहीं चाहिए (Don't want)": "no thanks refusing rejecting",
    "पसंद नहीं है (Don't like)": "dislike thumbs down",
    "नहीं है (Not here/have)": "empty nothing absent",
    "मालूम नहीं (Don't know)": "confused shrugging don't know",
    "कुछ नहीं (Nothing)": "nothing empty hands",
    "मैं नहीं गया (I didn't go)": "stayed behind did not go",
    # L11: Auto/Cab
    "सीधा जाओ": "go straight ahead road",
    "दाएं मुड़ो (Right)": "turn right arrow",
    "बाएं मुड़ो (Left)": "turn left arrow",
    "खुल्ले पैसे हैं क्या? (Change?)": "loose change coins",
    "मीटर डालो": "taxi meter start",
    "कितना हुआ?": "how much total fare bill",
    # L12: Complex Sentences
    "अगर तुम आओगे तो (If you come)": "if then conditional thinking",
    "जाने के बाद (After going)": "after leaving departure",
    "मुझे लगा कि... (I thought that...)": "thinking person thought bubble",
    "क्योंकि (Because)": "because reason explanation",
    "इसलिए (So/Therefore)": "therefore conclusion result",
    # L13: Numbers
    "एक (1)": "number one",
    "दो (2)": "number two",
    "तीन (3)": "number three",
    "चार (4)": "number four",
    "पाँच (5)": "number five",
    "छः (6)": "number six",
    "सात (7)": "number seven",
    "आठ (8)": "number eight",
    "नौ (9)": "number nine",
    "दस (10)": "number ten",
    "बीस (20)": "number twenty",
    "सौ (100)": "number hundred",
    "हज़ार (1000)": "number thousand",
    # L14: Time Expressions
    "आज": "today calendar current day",
    "कल (Yesterday)": "yesterday past day",
    "कल (Tomorrow)": "tomorrow future next day",
    "परसों": "day after tomorrow",
    "सुबह": "morning sunrise dawn",
    "दोपहर": "afternoon midday sun overhead",
    "शाम": "evening sunset dusk",
    "रात": "night moon stars dark sky",
    "हफ्ता": "week seven days calendar",
    "महीना": "month calendar page",
    "साल": "year twelve months",
    "कितने बजे?": "what time clock",
    # L15: Family Terms
    "माँ": "mother mom woman",
    "पापा": "father dad man",
    "बड़ा भाई": "elder brother older sibling",
    "छोटा भाई": "younger brother small sibling",
    "बड़ी बहन": "elder sister older sibling woman",
    "छोटी बहन": "younger sister small sibling girl",
    "पति": "husband married man",
    "पत्नी": "wife married woman",
    "बेटा": "son boy young",
    "बेटी": "daughter girl young",
    "दादा/नाना": "grandfather elderly man",
    "दादी/नानी": "grandmother elderly woman",
    "चाचा/मामा": "uncle man",
    "चाची/मामी": "aunt woman",
    # L16: Food & Dining
    "खाना": "food meal plate",
    "पानी": "water glass drinking",
    "चाय": "tea cup chai",
    "कॉफी": "coffee cup hot beverage",
    "चावल": "rice white cooked",
    "सांबर": "sambar South Indian lentil soup",
    "रसम": "rasam South Indian tomato soup",
    "दाल": "dal lentils yellow curry",
    "सब्जी": "vegetable dish sabzi",
    "मांस": "meat dish",
    "मछली": "fish seafood",
    "चिकन": "chicken poultry dish",
    "अंडा": "egg",
    "दूध": "milk glass white",
    "मिठाई": "sweets Indian dessert",
    "तीखा/मसालेदार": "spicy hot chili pepper",
    "नमकीन": "salty snack savory",
    "मीठा": "sweet sugary dessert",
    # L17: Restaurant Phrases
    "मेनू दीजिए": "restaurant menu card",
    "यह क्या है?": "what is this pointing curious",
    "एक और (One more)": "one more adding extra",
    "बिल लाओ": "restaurant bill check receipt",
    "बहुत स्वादिष्ट": "delicious tasty yummy food",
    "पेट भर गया": "full stomach satisfied after eating",
    "पैक कर दो": "packing food takeaway container",
    "थोड़ा कम मसाला": "less spice mild seasoning",
    "बिना प्याज़": "no onion crossed out",
    "शाकाहारी": "vegetarian plant based food",
    "मांसाहारी": "non-vegetarian meat dish",
    # L18: Shopping Essentials
    "यह कितने का है?": "price tag how much cost",
    "बहुत महँगा है": "too expensive money sad",
    "कुछ कम करो": "bargaining haggling discount",
    "ठीक है, दे दो": "okay I will take it buying",
    "दूसरा दिखाओ": "show another option variety",
    "बड़ा साइज़": "large size big",
    "छोटा साइज़": "small size little",
    "यह चाहिए": "I want this pointing selecting",
    "नहीं चाहिए": "don't want refusing shopping",
    "कहाँ मिलेगा?": "where can I find searching store",
    "थैला दो": "give me a bag shopping bag",
    # L19: Greetings & Pleasantries
    "शुभ प्रभात": "good morning sunrise greeting",
    "शुभ रात्रि": "good night moon stars greeting",
    "धन्यवाद": "thank you grateful thanks",
    "माफ़ कीजिए": "sorry apology forgiveness",
    "क्षमा करें (Excuse me)": "excuse me polite attention",
    "कैसे हो?": "how are you friendly greeting",
    "मैं ठीक हूँ": "I am fine smiling happy",
    "फिर मिलते हैं": "see you again goodbye wave",
    "अलविदा": "goodbye farewell waving",
    "आपका नाम क्या है?": "what is your name introduction",
    "मेरा नाम ___ है": "my name is introduction self",
    "मिलकर खुशी हुई": "nice to meet you handshake",
    # L20: Emotions & Feelings
    "खुश": "happy joyful smiling face",
    "दुखी": "sad unhappy crying face",
    "गुस्सा": "angry furious upset face",
    "डर": "fear scared frightened face",
    "थका हुआ": "tired exhausted sleepy",
    "बोर हो रहा है": "bored yawning uninterested",
    "चिंतित": "worried anxious nervous",
    "उत्साहित": "excited enthusiastic pumped up",
    # L21: Future Tense
    "मैं जाऊँगा": "I will go future walking",
    "मैं आऊँगा": "I will come future arriving",
    "वह देगा": "he will give future handing",
    "हम करेंगे": "we will do future teamwork",
    "देखेंगे (Let's see)": "let us see future thinking",
    "हो जाएगा": "it will happen future optimistic",
    "बताऊँगा/बताऊँगी": "I will tell speaking future",
    "कल मिलते हैं": "see you tomorrow waving goodbye",
    # L22: Ability & Permission
    "मैं कर सकता हूँ": "I can do it capable strong",
    "मैं नहीं कर सकता": "I cannot unable struggling",
    "क्या मैं जा सकता हूँ?": "may I go asking permission",
    "क्या हो सकता है?": "what could happen possibility",
    "आप कर सकते हैं": "you can do it encouraging",
    "इजाज़त है?": "permission allowed asking",
    "ठीक है, करो": "okay go ahead approving",
    "मत करो": "don't do it warning stop",
    # L23: Wants & Needs
    "मुझे चाहिए": "I need want desire",
    "मुझे नहीं चाहिए": "I don't need rejecting",
    "आपको क्या चाहिए?": "what do you need asking",
    "थोड़ा और चाहिए": "need a little more requesting",
    "बस, काफी है": "enough sufficient stop",
    "ज़रूरी है": "necessary important essential",
    "ज़रूरी नहीं है": "not necessary optional",
    "मुझे ___ पसंद है": "I like love heart favorite",
    # L24: Common Adjectives
    "अच्छा": "good nice thumbs up",
    "बुरा": "bad negative thumbs down",
    "बड़ा": "big large elephant",
    "छोटा": "small tiny little",
    "नया": "new shiny fresh",
    "पुराना": "old ancient vintage",
    "गर्म": "hot warm flame fire",
    "ठंडा": "cold cool ice frozen",
    "सुंदर": "beautiful pretty lovely flower",
    "आसान": "easy simple effortless",
    "मुश्किल": "difficult hard challenging",
    "सस्ता": "cheap affordable low price",
    "महँगा": "expensive costly luxury",
    "सही": "correct right checkmark",
    "गलत": "wrong incorrect cross mark",
    # L25: Frequency Words
    "हमेशा": "always forever every time",
    "कभी-कभी": "sometimes occasionally",
    "कभी नहीं": "never not ever",
    "रोज़/हर दिन": "daily every day routine",
    "अक्सर": "often frequently regularly",
    "ज़्यादातर": "mostly usually typically",
    "पहली बार": "first time new beginning",
    "फिर से": "again repeat once more",
    # L26: Possessives
    "मेरा": "mine my belonging self",
    "तेरा": "yours your belonging casual",
    "आपका": "yours your belonging respectful",
    "उसका (Male)": "his belonging male",
    "उसका (Female)": "hers belonging female",
    "उनका (Respect)": "theirs belonging respectful",
    "हमारा": "ours our belonging group",
    "किसका?": "whose belonging question",
    # L27: Phone & Digital
    "फ़ोन करो": "phone call mobile ringing",
    "मैसेज करो": "text message typing phone",
    "WhatsApp करो": "messaging chat online",
    "फ़ोटो भेजो": "send photo camera image",
    "लोकेशन भेजो": "send location map pin GPS",
    "नेटवर्क नहीं है": "no network signal lost",
    "बैटरी खत्म": "battery dead low power",
    "चार्जर दो": "phone charger cable plug",
    "WiFi पासवर्ड क्या है?": "WiFi password connection",
    # L28: Office & Work
    "काम": "work job office desk",
    "मीटिंग": "meeting conference room",
    "बॉस": "boss manager office leader",
    "सहकर्मी": "colleague coworker teammate",
    "छुट्टी": "holiday vacation day off",
    "तनख्वाह": "salary paycheck money wages",
    "देर हो गई": "running late delayed clock",
    "काम खत्म": "work finished done completed",
    "मुझे जाना है": "I have to go leaving",
    "व्यस्त हूँ": "busy occupied working",
    "ईमेल भेजो": "send email computer message",
    # L29: Health & Body
    "सिर": "head face top",
    "पेट": "stomach belly tummy",
    "हाथ": "hand palm fingers",
    "पैर": "foot leg walking",
    "आँख": "eye seeing vision",
    "कान": "ear hearing listening",
    "सिरदर्द है": "headache pain head",
    "पेट दर्द है": "stomach ache pain belly",
    "बुख़ार है": "fever thermometer sick",
    "सर्दी/जुकाम": "cold runny nose sneezing",
    "खाँसी": "cough sick throat",
    "डॉक्टर के पास जाना है": "going to doctor hospital",
    "दवाई": "medicine pills tablets",
    # L30: Emergency Phrases
    "मदद करो!": "help emergency urgent SOS",
    "पुलिस बुलाओ": "call police emergency",
    "एम्बुलेंस बुलाओ": "call ambulance emergency",
    "हॉस्पिटल कहाँ है?": "where is hospital medical",
    "आग लगी है!": "fire burning flames emergency",
    "चोर!": "thief robber stealing",
    "मुझे खो गया/गई": "lost confused cannot find way",
    "जल्दी करो!": "hurry up quickly rush",
    # L31: Agreement & Opinions
    "सही बात है": "that is right agreeing",
    "मैं सहमत हूँ": "I agree nodding yes",
    "मैं सहमत नहीं हूँ": "I disagree shaking head no",
    "मुझे लगता है": "I think opinion thought bubble",
    "शायद": "maybe perhaps uncertain",
    "पक्का/ज़रूर": "definitely surely certain",
    "मुझे नहीं पता": "I don't know shrugging confused",
    "अच्छा विचार है": "good idea lightbulb",
    "मुझे परवाह नहीं": "I don't care indifferent",
    # L32: Comparisons
    "इससे बड़ा": "bigger larger comparison",
    "इससे छोटा": "smaller tinier comparison",
    "इससे अच्छा": "better improved comparison",
    "ज़्यादा": "more quantity increased",
    "कम": "less fewer decreased",
    "सबसे अच्छा": "best number one trophy",
    "बराबर": "equal same balanced",
    "जैसा": "like similar as comparison",
    "अलग": "different unique distinct",
    # L33: Days of the Week
    "सोमवार": "Monday first day of week",
    "मंगलवार": "Tuesday second day of week",
    "बुधवार": "Wednesday midweek",
    "गुरुवार": "Thursday calendar day",
    "शुक्रवार": "Friday end of workweek",
    "शनिवार": "Saturday weekend relaxing",
    "रविवार": "Sunday weekend holiday",
    "आज कौन सा दिन है?": "what day is today calendar",
    # L34: Weather & Climate
    "बारिश": "rain clouds water drops",
    "धूप": "sunshine bright sunny day",
    "गर्मी है": "hot summer heat sun",
    "ठंड है": "cold winter chill snow",
    "बादल": "clouds cloudy overcast sky",
    "हवा": "wind breeze blowing air",
    "बहुत गर्मी है": "very hot scorching summer heat",
    "मौसम अच्छा है": "pleasant nice weather outdoors",
    # L35: Small Talk
    "अच्छा": "oh I see understanding",
    "सच में?": "really truly surprised",
    "क्या बात है!": "wow amazing wonderful",
    "बहुत बढ़िया!": "very good excellent great",
    "कोई बात नहीं": "no worries its okay",
    "एक मिनट": "one minute wait briefly",
    "देखते हैं": "let us see we will see",
    "पता नहीं": "don't know uncertain",
    "वैसे...": "by the way casual conversation",
    "असल में": "actually in fact reality",
    "बस ऐसे ही": "just like that casually",
    "क्या करें": "what to do helpless",
    # L36: Places & Locations
    "घर": "house home building",
    "स्कूल": "school classroom education",
    "अस्पताल": "hospital medical building",
    "बाज़ार": "market bazaar shopping street",
    "स्टेशन": "railway station train platform",
    "बस स्टॉप": "bus stop public transport",
    "मंदिर": "temple Hindu prayer",
    "बैंक": "bank financial building",
    "होटल": "hotel restaurant building",
    "ATM": "ATM cash machine",
    "पुलिस स्टेशन": "police station law enforcement",
    "पार्क": "park garden trees green",
    # L37: Colors
    "लाल": "red color",
    "नीला": "blue color",
    "हरा": "green color",
    "पीला": "yellow color",
    "काला": "black color",
    "सफ़ेद": "white color",
    "भूरा": "brown color",
    "गुलाबी": "pink color",
    # L38: Daily Routine Verbs
    "उठना": "wake up morning alarm rising",
    "नहाना": "bathing shower cleaning",
    "कपड़े पहनना": "getting dressed wearing clothes",
    "खाना बनाना": "cooking kitchen preparing food",
    "धोना": "washing cleaning laundry",
    "सफाई करना": "cleaning sweeping mopping",
    "पढ़ना": "reading book studying",
    "लिखना": "writing pen paper",
    "बोलना": "speaking talking mouth",
    "सुनना": "listening hearing ear",
    "चलना": "walking strolling person",
    "दौड़ना": "running jogging fast",
    # L39: Obligation
    "मुझे जाना है": "I must go obligation leaving",
    "मुझे करना है": "I have to do it obligation task",
    "आपको आना चाहिए": "you should come invitation",
    "जाना पड़ेगा": "will have to go must leave",
    "करना पड़ेगा": "will have to do must complete",
    "देखना है": "need to see look check",
    "बोलना है": "need to speak say tell",
    "ज़रूरत नहीं है": "no need unnecessary",
    # L40: Invitations & Requests
    "कृपया": "please polite request",
    "क्या आप ___ कर सकते हैं?": "can you please request asking politely",
    "आइए": "please come welcome invitation",
    "बैठिए": "please sit down chair polite",
    "खाइए": "please eat food polite serving",
    "थोड़ा इंतज़ार कीजिए": "please wait patience clock",
    "यह ले लीजिए": "please take this offering gift",
    "मदद कीजिए": "please help assistance polite",
    # L41: Causatives
    "करवाओ": "get it done delegating task",
    "भेजवाओ": "get it sent delivery dispatch",
    "बनवाओ": "get it made manufactured built",
    "बुलवाओ": "get someone called invite summon",
    "उसे बोलो": "tell that person instruct convey",
    "आने दो": "let come allow enter",
    "जाने दो": "let go allow leave release",
    # L42: Conditionals
    "अगर हो सके तो": "if possible maybe wish",
    "अगर समय हो": "if there is time clock busy",
    "मैं करता अगर...": "I would have done regret past",
    "काश ऐसा होता": "I wish it were so dreaming hope",
    "चाहिए था": "should have done past regret",
    "नहीं करना चाहिए था": "should not have done mistake regret",
    # L43: Reported Speech
    "उसने कहा कि...": "he said that speaking reporting",
    "उसने पूछा कि...": "he asked that questioning",
    "मैंने सुना कि...": "I heard that listening gossip",
    "लोग कहते हैं": "people say rumor word of mouth",
    "उन्होंने बताया": "they told informed",
    "सुना है कि...": "heard that news information",
    # L44: Question Tags
    "है ना?": "right question confirmation yes",
    "सही है ना?": "is that correct verification",
    "समझे?": "understood comprehension check",
    "आएंगे ना?": "you will come right expecting",
    "पता है?": "did you know awareness",
    "देखा?": "did you see noticed",
    # L45: Duration
    "कितनी देर?": "how long duration time",
    "पाँच मिनट में": "in five minutes soon clock",
    "एक घंटे में": "in one hour clock time",
    "थोड़ी देर": "a short while brief moment",
    "बहुत देर": "a long time waiting ages",
    "___ से": "since from starting point time",
    "___ तक": "until up to ending point time",
    "पूरे दिन": "the whole day all day long",
    # L46: Cultural & Social
    "शादी": "wedding marriage celebration",
    "त्यौहार": "festival celebration cultural",
    "पोंगल की शुभकामनाएं": "Pongal festival harvest South Indian celebration",
    "दीपावली की शुभकामनाएं": "Diwali festival of lights lamps celebration",
    "जन्मदिन मुबारक": "happy birthday cake celebration",
    "बधाई हो!": "congratulations party celebration",
    "शुभ विवाह": "happy wedding blessing marriage",
    "पूजा": "prayer worship temple ritual",
    # L47: Money & Banking
    "पैसे": "money cash currency",
    "रुपये": "rupees Indian currency",
    "खाता": "bank account ledger",
    "जमा करो": "deposit money into bank",
    "निकालो": "withdraw money from bank",
    "UPI से भेजो": "UPI digital payment phone transfer",
    "बैलेंस चेक करो": "check balance bank account",
    "पेमेंट हो गया": "payment completed done success",
    # L48: Giving Directions
    "सीधा जाओ": "go straight ahead road forward",
    "मोड़ के बाद": "after the turn corner road",
    "सामने": "in front ahead facing forward",
    "पीछे": "behind back rear",
    "बगल में": "beside next to adjacent",
    "ऊपर": "up above upward arrow",
    "नीचे": "down below downward arrow",
    "कोने पर": "at the corner intersection",
    "सिग्नल पर": "at the traffic signal lights",
    "फ्लाईओवर के बाद": "after the flyover bridge overpass",
    # L49: Entertainment & Leisure
    "फ़िल्म/मूवी": "movie film cinema popcorn",
    "गाना": "song music singing",
    "खेल": "game sport playing",
    "क्रिकेट": "cricket bat ball sport",
    "शॉपिंग": "shopping bags store mall",
    "घूमना": "traveling exploring sightseeing",
    "पार्टी": "party celebration fun friends",
    "फ़िल्म देखना है": "want to watch a movie cinema",
    "मज़ा आया": "had fun enjoyed happy",
    # L50: Advanced Connectors
    "हालांकि": "however although nevertheless",
    "जबकि": "whereas while contrast",
    "इसके अलावा": "besides apart from additionally",
    "इसके बावजूद": "despite in spite of nevertheless",
    "अगर...नहीं तो": "if not otherwise else",
    "जैसे ही": "as soon as immediately when",
    "जब तक": "until as long as duration",
    "ताकि": "so that in order to purpose",
    # Additional words not in standard lessons
    "मुझे अच्छा लग रहा है": "I am feeling good happy well",
    "तबियत ठीक नहीं है": "not feeling well sick unwell",
    "मुझे पसंद है": "I like it love favorite heart",
    "मुझे पसंद नहीं है": "I don't like it dislike thumbs down",
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    with open(CONTENT_JSON, "r", encoding="utf-8") as f:
        lessons = json.load(f)

    added = 0
    already = 0
    missing = 0

    for lesson in lessons:
        for word in lesson.get("words", []):
            hindi = word["hindi"]

            # Already has english field
            if word.get("english"):
                already += 1
                continue

            # Look up in mapping
            if hindi in HINDI_TO_ENGLISH:
                word["english"] = HINDI_TO_ENGLISH[hindi]
                added += 1
            else:
                # Try extracting from parentheses
                m = re.search(r"\(([A-Za-z][A-Za-z /\-']+)\)", hindi)
                if m:
                    word["english"] = m.group(1).strip()
                    added += 1
                else:
                    missing += 1
                    print(f"  MISSING: '{hindi}'")

    print(f"\nAdded: {added}, Already had: {already}, Still missing: {missing}")

    if not args.dry_run and added > 0:
        with open(CONTENT_JSON, "w", encoding="utf-8") as f:
            json.dump(lessons, f, ensure_ascii=False, indent=2)
        print(f"Wrote {CONTENT_JSON}")
    elif args.dry_run:
        print("(dry-run — no changes written)")


if __name__ == "__main__":
    main()
