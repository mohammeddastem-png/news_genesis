#!/usr/bin/env python3
"""
News Genesis: Live Dubbing Worker (Advanced Edge-TTS Edition)
Features: Gemini 2.5 Translation, Edge-TTS (Natural Voices), Firebase Sync.
"""
from __future__ import annotations

import json
import os
import sys
import tempfile
import asyncio
from datetime import timedelta

import firebase_admin
from firebase_admin import credentials, db, storage

# --- 1. Firebase Initialization ---
def init_firebase():
    raw = os.environ.get("FIREBASE_SERVICE_ACCOUNT_KEY", "").strip()
    if not raw:
        print("❌ FIREBASE_SERVICE_ACCOUNT_KEY missing", file=sys.stderr)
        sys.exit(1)
    
    info = json.loads(raw)
    cred = credentials.Certificate(info)
    bucket = os.environ.get("FIREBASE_STORAGE_BUCKET") or "newsgenesis-59790.firebasestorage.app"
    db_url = "https://newsgenesis-59790-default-rtdb.firebaseio.com"
    
    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred, {"databaseURL": db_url, "storageBucket": bucket})
    print("✅ Firebase Connected Successfully.")

# --- 2. Gemini Translation Logic ---
def gemini_translate(text: str, target_code: str, api_key: str) -> str:
    import google.generativeai as genai
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel("gemini-1.5-flash") # Stable version
    
    prompt = f"""You are a professional broadcast-news translator.
Translate from English to language code "{target_code}".
Maintain a serious news tone. Output only the translated text.
English: {text}"""
    
    r = model.generate_content(prompt)
    out = (r.text or "").strip()
    if not out:
        raise RuntimeError("Empty translation from Gemini")
    return out

# --- 3. Advanced Edge-TTS Voice Mapping ---
def get_edge_voice(lang_code: str, speaker_type="male") -> str:
    # മലയാളം, ഹിന്ദി തുടങ്ങിയവയ്ക്കുള്ള മികച്ച ന്യൂറൽ വോയിസുകൾ
    mapping = {
        "ml": {"male": "ml-IN-MidhunNeural", "female": "ml-IN-SobhanaNeural"},
        "hi": {"male": "hi-IN-MadhurNeural", "female": "hi-IN-SwararaNeural"},
        "ta": {"male": "ta-IN-ValluvarNeural", "female": "ta-IN-PallaviNeural"},
        "ur": {"male": "ur-PK-AsadNeural", "female": "ur-PK-UzmaNeural"}
    }
    lang = lang_code.lower()[:2]
    voices = mapping.get(lang, {"male": "en-IN-PrabhatNeural", "female": "en-IN-NeerjaNeural"})
    return voices.get(speaker_type)

async def synth_edge_mp3(text: str, voice: str, out_path: str):
    import edge_tts
    communicate = edge_tts.Communicate(text, voice)
    await communicate.save(out_path)

# --- 4. Audio Processing & Upload ---
def process_audio_duration(path: str, min_ms: int):
    from pydub import AudioSegment
    seg = AudioSegment.from_mp3(path)
    # വാർത്താ വായനയ്ക്കിടയിലുള്ള സൈലൻസ് (നിങ്ങൾ ആവശ്യപ്പെട്ട minAudioSec ഉറപ്പാക്കാൻ)
    if len(seg) < min_ms:
        silence = AudioSegment.silent(duration=(min_ms - len(seg)) + 1000)
        seg = seg + silence
    seg.export(path, format="mp3")
    return len(seg) / 1000.0

def upload_to_firebase(job_id: str, local_path: str):
    bucket = storage.bucket()
    blob = bucket.blob(f"dubbing_jobs/{job_id}/dub.mp3")
    blob.upload_from_filename(local_path, content_type="audio/mpeg")
    # 7 ദിവസത്തേക്ക് വാലിഡിറ്റിയുള്ള സൈൻഡ് യുആർഎൽ
    return blob.generate_signed_url(version="v4", expiration=timedelta(days=7), method="GET")

# --- 5. Main Processing Loop ---
async def process_job(job_id: str, data: dict):
    api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not api_key: raise RuntimeError("GEMINI_API_KEY missing")

    ref = db.reference(f"dubbing_jobs/{job_id}")
    ref.update({"status": "processing"})

    source_text = (data.get("sourceEnglish") or "").strip()
    target_lang = (data.get("targetLangCode") or "ml").strip()
    min_sec = int(data.get("minAudioSec") or 20)
    
    # 1. Translate
    translated_text = gemini_translate(source_text, target_lang, api_key)
    
    # 2. Synthesize Voice (Edge-TTS)
    voice_model = get_edge_voice(target_lang)
    
    with tempfile.TemporaryDirectory() as tmp:
        mp3_path = os.path.join(tmp, "dub.mp3")
        await synth_edge_mp3(translated_text, voice_model, mp3_path)
        
        # 3. Adjust duration & Upload
        final_duration = process_audio_duration(mp3_path, min_sec * 1000)
        audio_url = upload_to_firebase(job_id, mp3_path)

    # 4. Final Update to RTDB
    ref.update({
        "status": "ready",
        "translatedText": translated_text,
        "audioUrl": audio_url,
        "durationSec": final_duration,
        "processedAt": {".sv": "timestamp"}
    })
    print(f"✅ Job {job_id} Completed. Duration: {final_duration}s")

def main():
    init_firebase()
    jobs_ref = db.reference("dubbing_jobs")
    snap = jobs_ref.get()
    
    if not snap:
        print("📡 No pending jobs found.")
        return

    for job_id, data in snap.items():
        if isinstance(data, dict) and data.get("status") == "pending":
            try:
                asyncio.run(process_job(str(job_id), data))
            except Exception as e:
                print(f"❌ FAIL {job_id}: {e}")
                db.reference(f"dubbing_jobs/{job_id}").update({"status": "error", "error": str(e)})

if __name__ == "__main__":
    main()