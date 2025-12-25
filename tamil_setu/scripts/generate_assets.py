import os
import json
import time
from pathlib import Path
from gtts import gTTS
from aksharamukha import transliterate

# --- 1. SETUP PATHS ---
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
ASSETS_DIR = PROJECT_ROOT / "assets"

print(f"📂 Project Root: {PROJECT_ROOT}")

# --- 2. CURRICULUM (13 Levels) ---
curriculum = [
    # --- LEVEL 1: BASICS ---
    {
        "level": 1, "topic": "Basics (Greet)", 
        "description": "Start with Namaste and basic questions.",
        "items": [
            ("नमस्ते", "வணக்கம்", "l1_namaste"),
            ("कैसे हो?", "எப்படி இருக்கிறீர்கள்?", "l1_kaise_ho"), 
            ("मैं ठीक हूँ", "நான் நன்றாக இருக்கிறேன்", "l1_main_theek"),
            ("क्या?", "என்ன?", "l1_kya"),
            ("नाम", "பெயர்", "l1_naam"),
            ("धन्यवाद", "நன்றி", "l1_dhanyavaad"),
            ("माफ़ कीजिये", "மன்னிக்கவும்", "l1_sorry"),
            ("हाँ", "ஆம்", "l1_haan"),
            ("नहीं", "இல்லை", "l1_nahi")
        ]
    },
    # --- LEVEL 2: PRONOUNS ---
    {
        "level": 2, "topic": "Pronouns", 
        "description": "Me, You, This, That",
        "items": [
            ("मैं", "நான்", "l2_main"),
            ("तुम", "நீ", "l2_tum"),
            ("आप", "நீங்கள்", "l2_aap"),
            ("यह (व्यक्ति)", "இவர்", "l2_yeh_person"),
            ("वह (व्यक्ति)", "அவர்", "l2_woh_person"),
            ("हम", "நாங்கள்", "l2_hum"),
            ("ये लोग", "இவர்கள்", "l2_ye_log"),
            ("वे लोग", "அவர்கள்", "l2_wo_log")
        ]
    },
    # --- LEVEL 3: VERBS ---
    {
        "level": 3, "topic": "Common Verbs", 
        "description": "Action words for daily life.",
        "items": [
            ("आना", "வா", "l3_aana"),
            ("जाना", "போ", "l3_jaana"),
            ("खाना", "சாப்பிடு", "l3_khana"),
            ("पीना", "குடி", "l3_peena"),
            ("सोना", "தூங்கு", "l3_sona"),
            ("उठना", "எழுந்திரு", "l3_uthna"),
            ("देखना", "பார்", "l3_dekhna"),
            ("सुनना", "கேள்", "l3_sunna"),
            ("बोलना", "பேசு", "l3_bolna")
        ]
    },
    # --- LEVEL 4: NUMBERS ---
    {
        "level": 4, "topic": "Numbers (1-10)", 
        "description": "Counting in Tamil",
        "items": [
            ("एक", "ஒன்று", "l4_one"),
            ("दो", "இரண்டு", "l4_two"),
            ("तीन", "மூன்று", "l4_three"),
            ("चार", "நான்கு", "l4_four"),
            ("पाँच", "ஐந்து", "l4_five"),
            ("छह", "ஆறு", "l4_six"),
            ("सात", "ஏழு", "l4_seven"),
            ("आठ", "எட்டு", "l4_eight"),
            ("नौ", "ஒன்பது", "l4_nine"),
            ("दस", "பத்து", "l4_ten")
        ]
    },
    # --- LEVEL 5: FAMILY ---
    {
        "level": 5, "topic": "Family", 
        "description": "Relationships",
        "items": [
            ("माँ", "அம்மா", "l5_maa"),
            ("पिता", "அப்பா", "l5_papa"),
            ("भाई", "சகோதரன்", "l5_bhai"),
            ("बहन", "சகோதரி", "l5_behen"),
            ("दादा/दादी", "தாத்தா பாட்டி", "l5_grandparents"),
            ("बेटा", "மகன்", "l5_son"),
            ("बेटी", "மகள்", "l5_daughter"),
            ("पति", "கணவன்", "l5_husband"),
            ("पत्नी", "மனைவி", "l5_wife")
        ]
    },
    # --- LEVEL 6: COLORS ---
    {
        "level": 6, "topic": "Colors", 
        "description": "Colors of the world",
        "items": [
            ("लाल", "சிவப்பு", "l6_red"),
            ("नीला", "நீலம்", "l6_blue"),
            ("हरा", "பச்சை", "l6_green"),
            ("पीला", "மஞ்சள்", "l6_yellow"),
            ("काला", "கருப்பு", "l6_black"),
            ("सफेद", "வெள்ளை", "l6_white"),
            ("गुलाबी", "இளஞ்சிவப்பு", "l6_pink"),
            ("नारंगी", "ஆரஞ்சு", "l6_orange")
        ]
    },
    # --- LEVEL 7: FOOD ---
    {
        "level": 7, "topic": "Food & Drinks",
        "description": "Common food items",
        "items": [
            ("पानी", "தண்ணீர்", "l7_water"),
            ("चावल", "சாதம்", "l7_rice"),
            ("रोटी", "சப்பாத்தி", "l7_roti"),
            ("दूध", "பால்", "l7_milk"),
            ("चाय", "தேநீர்", "l7_tea"),
            ("फल", "பழம்", "l7_fruit")
        ]
    },
    # --- LEVEL 8: TIME ---
    {
        "level": 8, "topic": "Time & Days",
        "description": "Expressing time",
        "items": [
            ("आज", "இன்று", "l8_today"),
            ("कल (बीता)", "நேற்று", "l8_yesterday"),
            ("कल (आने वाला)", "நாளை", "l8_tomorrow"),
            ("सुबह", "காலை", "l8_morning"),
            ("शाम", "மாலை", "l8_evening"),
            ("रात", "இரவு", "l8_night")
        ]
    },
    # --- LEVEL 9: GRAMMAR (CASES) ---
    {
        "level": 9, "topic": "Grammar (Cases)",
        "description": "Connecting words (Ko, Se, Mein)",
        "items": [
            ("राम को", "ராமனுக்கு", "l9_ko"),     
            ("घर से", "வீட்டிலிருந்து", "l9_se"), 
            ("घर में", "வீட்டில்", "l9_mein"),
            ("मेरे लिए", "எனக்காக", "l9_for_me")
        ]
    },
    # --- LEVEL 10: FULL SENTENCES ---
    {
        "level": 10, "topic": "Full Sentences",
        "description": "Real Conversation Phrases",
        "items": [
            ("मेरा नाम प्रणव है", "என் பெயர் பிரணவ்", "l10_my_name"),
            ("खाना खाया?", "சாப்பிட்டீர்களா?", "l10_ate"),
            ("मुझे प्यास लगी है", "எனக்குத் தாகமாக இருக்கிறது", "l10_thirsty"),
            ("पानी चाहिए", "தண்ணீர் வேண்டும்", "l10_want_water"),
            ("यह क्या है?", "இது என்ன?", "l10_what_is_this"),
            ("आपका घर कहाँ है?", "உங்கள் வீடு எங்கே?", "l10_where_is_house")
        ]
    }
]

# --- 3. GENERATION ENGINE ---
def generate_assets():
    audio_dir = ASSETS_DIR / "audio"
    data_dir = ASSETS_DIR / "data"
    os.makedirs(audio_dir, exist_ok=True)
    os.makedirs(data_dir, exist_ok=True)
    
    master_data = []

    print(f"\n🎬 Starting Generation for {len(curriculum)} Levels...")

    for level in curriculum:
        level_list = []
        print(f"📦 Processing Level {level['level']}: {level['topic']}")
        
        for hindi, tamil, file_id in level['items']:
            # A. PRONUNCIATION (Tamil Script -> Devanagari Script)
            try:
                # Aksharamukha handles Script-to-Script conversion accurately
                # It uses strict phonetic mapping (e.g. Va -> Va, Na -> Na)
                pronunciation_text = transliterate.process("Tamil", "Devanagari", tamil)
            except Exception as e:
                print(f"   ⚠️ Transliteration Error: {e}")
                pronunciation_text = ""
            
            # B. AUDIO (Google TTS)
            try:
                # 'ta' is the code for Tamil
                tts = gTTS(text=tamil, lang='ta', slow=False)
                
                # Save as MP3 (gTTS uses MP3 by default)
                filename = f"{file_id}.mp3"
                audio_path = audio_dir / filename
                tts.save(str(audio_path))
                
                # Sleep briefly to avoid hitting Google's rate limit
                time.sleep(0.5)
                
                level_list.append({
                    "tamil": tamil,
                    "hindi": hindi,
                    "pronunciation": pronunciation_text,
                    "audio_path": f"assets/audio/{filename}"
                })
                # PRINT TO CONSOLE so you can verify the accuracy yourself!
                # print(f"   ✅ {hindi} -> {pronunciation_text} [Audio Saved]")
                
            except Exception as e:
                print(f"   ❌ Audio Failed: {file_id} - {e}")

        master_data.append({
            "level": level['level'],
            "title": level['topic'],
            "description": level['description'],
            "words": level_list
        })

    with open(data_dir / "master_content.json", "w", encoding="utf-8") as f:
        json.dump(master_data, f, ensure_ascii=False, indent=4)
        
    print(f"\n🎉 Success! Assets generated in: {ASSETS_DIR}")

if __name__ == "__main__":
    generate_assets()