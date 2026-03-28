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
    db_url = os.environ.get(
        "FIREBASE_DATABASE_URL",
        "https://newsgenesis-59790-default-rtdb.firebaseio.com",
    )

    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred, {"databaseURL": db_url, "storageBucket": bucket})
    print("✅ Firebase Connected Successfully.")

# --- 2. Gemini Translation (2.x മോഡൽ — 1.5-flash ഫ്രീ ടಿಯർ 429/ക്വോട്ട പിശക് കൊടുക്കും) ---
def gemini_translate(text: str, target_code: str, api_key: str) -> str:
    import time
    import google.generativeai as genai

    genai.configure(api_key=api_key)
    model_name = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash").strip()
    model = genai.GenerativeModel(model_name)
    prompt = f"""You are a professional broadcast-news translator.
Translate from English to language code "{target_code}".
Maintain a serious news tone. Output only the translated text.
English: {text[:12000]}"""

    last_err = None
    for attempt in range(5):
        try:
            r = model.generate_content(prompt)
            out = (r.text or "").strip()
            if not out:
                raise RuntimeError("Empty translation from Gemini")
            return out[:6000]
        except Exception as e:
            last_err = e
            msg = str(e).lower()
            if "429" in str(e) or "quota" in msg or "resource" in msg:
                wait = min(60, 4 * (2**attempt) + 2)
                print(f"⚠️ Gemini rate/quota, retry in {wait}s ({attempt + 1}/5)", flush=True)
                time.sleep(wait)
                continue
            raise
    raise RuntimeError(str(last_err))

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
    webhook = os.environ.get("DUBBING_WEBHOOK_URL", "").strip()
    api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not webhook and not api_key:
        raise RuntimeError("GEMINI_API_KEY അല്ലെങ്കിൽ DUBBING_WEBHOOK_URL വേണം")

    ref = db.reference(f"dubbing_jobs/{job_id}")
    ref.update({"status": "processing"})

    source_text = (data.get("sourceEnglish") or "").strip()[:8000]
    target_lang = (data.get("targetLangCode") or "ml").strip()
    min_sec = int(data.get("minAudioSec") or 20)
    sync_ts = float(data.get("syncSeconds") or 0)

    # ഓപ്ഷണൽ: കോളाब് URL — JSON മറുപടി: translatedText, audioBase64
    if webhook:
        try:
            import urllib.request
            import urllib.error
            body = json.dumps({
                "jobId": job_id,
                "sourceEnglish": source_text,
                "targetLangCode": target_lang,
                "syncSeconds": sync_ts,
            }).encode("utf-8")
            req = urllib.request.Request(
                webhook,
                data=body,
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=300) as resp:
                payload = json.loads(resp.read().decode())
            translated_text = (payload.get("translatedText") or "").strip()
            audio_b64 = (payload.get("audioBase64") or "").strip()
            if not translated_text or not audio_b64:
                raise RuntimeError("Webhook response missing translatedText or audioBase64")
            import base64
            with tempfile.TemporaryDirectory() as tmp:
                mp3_path = os.path.join(tmp, "dub.mp3")
                with open(mp3_path, "wb") as f:
                    f.write(base64.b64decode(audio_b64))
                final_duration = process_audio_duration(mp3_path, min_sec * 1000)
                audio_url = upload_to_firebase(job_id, mp3_path)
            ref.update({
                "status": "ready",
                "translatedText": translated_text,
                "audioUrl": audio_url,
                "durationSec": final_duration,
                "syncSeconds": sync_ts,
                "processedAt": int(__import__("time").time() * 1000),
            })
            print(f"✅ Job {job_id} via webhook. Duration: {final_duration}s")
            return
        except Exception as hook_err:
            print(f"⚠️ Webhook failed, falling back to Gemini+Edge: {hook_err}", flush=True)

    if not api_key:
        raise RuntimeError("ഫോൾബാക്ക് പൈപ്പ്ലൈന് GEMINI_API_KEY വേണം")

    # 1. Translate
    translated_text = gemini_translate(source_text, target_lang, api_key)
    
    # 2. Synthesize Voice (Edge-TTS)
    voice_model = get_edge_voice(target_lang) or "en-US-GuyNeural"
    
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
        "syncSeconds": sync_ts,
        "processedAt": int(__import__("time").time() * 1000),
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
                db.reference(f"dubbing_jobs/{job_id}").update({
                    "status": "error",
                    "errorMessage": str(e)[:800],
                })

if __name__ == "__main__":
    main()