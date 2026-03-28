#!/usr/bin/env python3
"""
News Genesis: Live Dubbing Worker (Cloudinary Edition - No Blaze Plan Needed)
Features: Gemini 2.5 Translation, Edge-TTS, Cloudinary Audio Storage.
"""
from __future__ import annotations

import json
import os
import sys
import tempfile
import asyncio
import time
from datetime import timedelta

import firebase_admin
from firebase_admin import credentials, db
import cloudinary
import cloudinary.uploader

# --- 1. Initialization ---
def init_services():
    # Firebase Init
    raw = os.environ.get("FIREBASE_SERVICE_ACCOUNT_KEY", "").strip()
    if not raw:
        print("❌ FIREBASE_SERVICE_ACCOUNT_KEY missing", file=sys.stderr)
        sys.exit(1)
    
    info = json.loads(raw)
    cred = credentials.Certificate(info)
    db_url = os.environ.get(
        "FIREBASE_DATABASE_URL",
        "https://newsgenesis-59790-default-rtdb.firebaseio.com",
    )

    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred, {"databaseURL": db_url})
    
    # Cloudinary Init
    cloudinary.config(
        cloud_name = os.environ.get("CLOUDINARY_CLOUD_NAME"),
        api_key = os.environ.get("CLOUDINARY_API_KEY"),
        api_secret = os.environ.get("CLOUDINARY_API_SECRET")
    )
    print("✅ Firebase & Cloudinary Connected Successfully.")

# --- 2. Gemini Translation ---
def gemini_translate(text: str, target_code: str, api_key: str) -> str:
    import google.generativeai as genai
    genai.configure(api_key=api_key)
    model_name = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash").strip()
    model = genai.GenerativeModel(model_name)
    prompt = f"Professional news translation to language code '{target_code}'. Output only translated text: {text[:10000]}"

    for attempt in range(3):
        try:
            r = model.generate_content(prompt)
            return (r.text or "").strip()
        except Exception as e:
            time.sleep(5)
    return "Translation Error"

# --- 3. Audio Processing ---
async def synth_edge_mp3(text: str, lang_code: str, out_path: str):
    import edge_tts
    mapping = {
        "ml": "ml-IN-MidhunNeural",
        "hi": "hi-IN-MadhurNeural",
        "ur": "ur-PK-AsadNeural"
    }
    voice = mapping.get(lang_code[:2], "en-IN-PrabhatNeural")
    communicate = edge_tts.Communicate(text, voice)
    await communicate.save(out_path)

def process_audio_duration(path: str, min_ms: int):
    from pydub import AudioSegment
    seg = AudioSegment.from_mp3(path)
    if len(seg) < min_ms:
        seg = seg + AudioSegment.silent(duration=(min_ms - len(seg)) + 500)
    seg.export(path, format="mp3")
    return len(seg) / 1000.0

def upload_to_cloudinary(local_path):
    # ഓഡിയോ ഫയലുകൾ ക്ലൗഡിനറിയിൽ 'video' എന്ന ടൈപ്പിലാണ് അപ്‌ലോഡ് ചെയ്യേണ്ടത്
    result = cloudinary.uploader.upload(local_path, resource_type="video")
    return result.get("secure_url")

# --- 4. Main Worker Logic ---
async def process_job(job_id: str, data: dict):
    api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    ref = db.reference(f"dubbing_jobs/{job_id}")
    ref.update({"status": "processing"})

    source_text = data.get("sourceEnglish", "")
    target_lang = data.get("targetLangCode", "ml")
    min_sec = int(data.get("minAudioSec", 15))

    # 1. Translate
    translated_text = gemini_translate(source_text, target_lang, api_key)
    
    # 2. TTS & Storage
    with tempfile.TemporaryDirectory() as tmp:
        mp3_path = os.path.join(tmp, "dub.mp3")
        await synth_edge_mp3(translated_text, target_lang, mp3_path)
        
        final_duration = process_audio_duration(mp3_path, min_sec * 1000)
        audio_url = upload_to_cloudinary(mp3_path)

    # 3. Update Firebase
    ref.update({
        "status": "ready",
        "translatedText": translated_text,
        "audioUrl": audio_url,
        "durationSec": final_duration,
        "processedAt": int(time.time() * 1000),
    })
    print(f"✅ Job {job_id} Success: {audio_url}")

def main():
    init_services()
    jobs = db.reference("dubbing_jobs").get()
    if not jobs: return

    for jid, data in jobs.items():
        if isinstance(data, dict) and data.get("status") == "pending":
            try:
                asyncio.run(process_job(str(jid), data))
            except Exception as e:
                print(f"❌ Error {jid}: {e}")
                db.reference(f"dubbing_jobs/{jid}").update({"status": "error", "errorMessage": str(e)})

if __name__ == "__main__":
    main()