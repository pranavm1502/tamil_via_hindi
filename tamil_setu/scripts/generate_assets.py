import os
import json
import time
import re
from pathlib import Path
from gtts import gTTS
from aksharamukha import transliterate

# --- 1. SETUP PATHS ---
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
ASSETS_DIR = PROJECT_ROOT / "assets"
DATA_FILE = ASSETS_DIR / "data" / "curriculum.json" 

print(f"📂 Project Root: {PROJECT_ROOT}")

# --- 2. GENERATION ENGINE ---
def generate_assets():
    audio_dir = ASSETS_DIR / "audio"
    data_dir = ASSETS_DIR / "data"
    os.makedirs(audio_dir, exist_ok=True)
    os.makedirs(data_dir, exist_ok=True)

    # Load Curriculum from external JSON
    try:
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            curriculum = json.load(f)
    except FileNotFoundError:
        print(f"❌ Error: {DATA_FILE} not found. Please create the JSON file first.")
        return

    master_data = []
    print(f"\n🎬 Starting Generation for {len(curriculum)} Levels...")

    for level in curriculum:
        level_list = []
        print(f"📦 Processing Level {level['level']}: {level['topic']}")
        
        for item in level['items']:
            # Extract fields
            hindi_text = item['hindi']
            # We are ignoring the 'formal' field in the output
            spoken_tamil = item['spoken']
            file_id = item['id']

            # A. PRONUNCIATION (Transliterate the SPOKEN version)
            try:
                # Clean romanized text in parentheses (e.g., "நான் (Naan)" -> "நான்")
                clean_tamil = re.sub(r'\s*\([^)]*\)', '', spoken_tamil).strip()
                # Transliteration for the colloquial text
                pronunciation_text = transliterate.process("Tamil", "Devanagari", clean_tamil)
            except Exception as e:
                print(f"   ⚠️ Transliteration Error: {e}")
                pronunciation_text = ""
            
            # B. AUDIO (Google TTS - uses the clean Tamil text)
            audio_filename = f"{file_id}.mp3"
            audio_path = audio_dir / audio_filename

            # Only generate if file doesn't exist
            if not audio_path.exists():
                try:
                    tts = gTTS(text=clean_tamil, lang='ta', slow=False)
                    tts.save(str(audio_path))
                    time.sleep(0.5) # Rate limiting
                except Exception as e:
                    print(f"   ❌ Audio Failed: {file_id} - {e}")

            # --- Use cleaned Tamil text (without romanization) ---
            level_list.append({
                "hindi": hindi_text,
                "tamil": clean_tamil,   # <-- Cleaned spoken colloquial Tamil
                "pronunciation": pronunciation_text,
                "audio_path": f"assets/audio/{audio_filename}"
            })

        master_data.append({
            "level": level['level'],
            "title": level['topic'],
            "description": level['description'],
            "words": level_list
        })

    # Save the compiled master content for the App to consume
    with open(data_dir / "master_content.json", "w", encoding="utf-8") as f:
        json.dump(master_data, f, ensure_ascii=False, indent=4)
        
    print(f"\n🎉 Success! Assets generated in: {ASSETS_DIR}")

if __name__ == "__main__":
    generate_assets()