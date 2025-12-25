import argparse
import torch
from transformers import VitsModel, AutoTokenizer
from ai4bharat.transliteration import XlitEngine
import scipy.io.wavfile
import json
import os

# --- 1. SECURITY & DEVICE SETUP ---
torch.serialization.add_safe_globals([argparse.Namespace])
device = "mps" if torch.backends.mps.is_available() else "cpu"
print(f"🚀 Using Device: {device.upper()}")

# --- 2. LOAD NATIVE MODELS ---
# MMS-TTS is used for high-quality, studio-like native Tamil phonetics.
model_name = "facebook/mms-tts-tam"
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = VitsModel.from_pretrained(model_name).to(device)
xlit_engine = XlitEngine("ta", beam_width=10, src_script_type="indic")

# --- 3. STRUCTURED CURRICULUM DATA ---
# Using Colloquial forms (e.g., 'Neenga' instead of 'Neengal') for native feel.
curriculum = [
    {"level": 1, "topic": "Basics", "items": [
        ("नमस्ते", "வணக்கம்", "l1_greet"),
        ("हाँ", "ஆம்", "l1_yes"),
        ("नहीं", "இல்லை", "l1_no"),
        ("ठीक है", "சரி", "l1_ok")
    ]},
    {"level": 2, "topic": "Pronouns", "items": [
        ("मैं", "நான்", "l2_i"),
        ("आप (सम्मानजनक)", "நீங்கள்", "l2_you"), # Aap -> Neenga
        ("यह", "இது", "l2_this"),
        ("वह", "அது", "l2_that")
    ]},
    {"level": 3, "topic": "Case Markers", "items": [
        ("राम को", "ராமனுக்கு", "l3_ko"),     # Ko -> -ukku
        ("घर से", "வீட்டிலிருந்து", "l3_se"), # Se -> -ilirundhu
        ("घर में", "வீட்டில்", "l3_mein")      # Mein -> -il
    ]},
    {"level": 4, "topic": "Verbs (Present)", "items": [
        ("मैं जा रहा हूँ", "நான் போகிறேன்", "l4_go"),
        ("मैं खा रहा हूँ", "நான் சாப்பிடுகிறேன்", "l4_eat"),
        ("मैं देख रहा हूँ", "நான் பார்க்கிறேன்", "l4_see")
    ]},
    {"level": 5, "topic": "Needs & Questions", "items": [
        ("यह क्या है?", "இது என்ன?", "l5_what"),
        ("पानी चाहिए", "தண்ணீர் வேண்டும்", "l5_want"),
        ("आपका घर कहाँ है?", "உங்கள் வீடு எங்கே?", "l5_where")
    ]}
]

# --- 4. GENERATION ENGINE ---
def generate_assets():
    os.makedirs("/../assets/audio", exist_ok=True)
    os.makedirs("/../assets/data", exist_ok=True)
    
    master_data = []

    for level in curriculum:
        level_list = []
        print(f"📦 Rendering Level {level['level']}: {level['topic']}")
        
        for hindi, tamil, file_id in level['items']:
            # A. Transliterate to Hindi Script (Bridge for learners)
            hindi_script = xlit_engine.translit_sentence(tamil, lang_code="hi")
            
            # B. Generate Studio-Quality Audio
            inputs = tokenizer(tamil, return_tensors="pt").to(device)
            with torch.no_grad(): # Fixed: Correct inference context
                output = model(**inputs).waveform
            
            audio_path = f"/../assets/audio/{file_id}.wav"
            audio_data = output.cpu().numpy().squeeze()
            scipy.io.wavfile.write(audio_path, rate=model.config.sampling_rate, data=audio_data)
            
            level_list.append({
                "tamil": tamil,
                "hindi_meaning": hindi,
                "hindi_pronunciation": hindi_script,
                "audio_file": audio_path
            })
        
        master_data.append({
            "level": level['level'],
            "topic": level['topic'],
            "lessons": level_list
        })

    with open("/../assets/data/master_content.json", "w", encoding="utf-8") as f:
        json.dump(master_data, f, ensure_ascii=False, indent=4)
    print("\n✅ All assets generated! Native voices and Hindi bridges ready.")

if __name__ == "__main__":
    generate_assets()