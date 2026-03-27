# 📰 News Genesis - Advanced News App Architecture Guide

**A full-stack news app with Live Streaming, AI Dubbing, Advanced Audio Processing, and 24/7 Web Scraping**

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER MOBILE APP                       │
│                   (iOS/Android/Web)                          │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Live Streaming   │  │ AI Dubbing Panel │                │
│  │ (HLS/m3u8)       │  │ (Gemini API)     │                │
│  └──────────────────┘  └──────────────────┘                │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ Audio Controls   │  │ Speaker Detection│                │
│  │ (Advanced)       │  │ (Diarization)    │                │
│  └──────────────────┘  └──────────────────┘                │
└─────────────────────────────────────────────────────────────┘
           │                    │                    │
           ▼                    ▼                    ▼
    ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
    │ Firebase     │   │ Gemini API   │   │ Google AdMob │
    │ Realtime DB  │   │ (Translation)│   │ (Monetization)
    │ + Storage    │   │ + TTS        │   │              │
    └──────────────┘   └──────────────┘   └──────────────┘
           │
           ▼
    ┌──────────────────────────────────────────────────────┐
    │      VPS Cloud Server (24/7 Scraper)                 │
    │  ┌────────────────────────────────────────────────┐ │
    │  │ Al Jazeera Web Scraper (FastAPI + BeautifulSoup) │
    │  │ - Scrapes English & Arabic channels               │
    │  │ - Extracts article, images, metadata               │
    │  │ - Stores in Firebase Realtime Database             │
    │  └────────────────────────────────────────────────┘ │
    └──────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### 1. Flutter App Setup

#### Install Dependencies
```bash
cd /Users/mohammedibrahimkommachikalathil/news_genesis
flutter pub get
```

#### Run the App
```bash
flutter run -d ios
# or
flutter run -d android
```

---

### 2. VPS Web Scraper Setup (24/7 Cloud Server)

#### Prerequisites
- VPS (AWS EC2, DigitalOcean, Linode - Ubuntu 22.04)
- SSH access to VPS
- Firebase project with credentials JSON

#### Step-by-Step Deployment

**Step 1: Connect to VPS**
```bash
ssh root@your_vps_ip_address
```

**Step 2: Install System Dependencies**
```bash
apt-get update && apt-get upgrade -y
apt-get install -y python3.11 python3-pip git curl wget
```

**Step 3: Clone Repository**
```bash
cd /root
git clone https://github.com/yourusername/news_genesis_scraper.git
cd news_genesis_scraper
```

**Step 4: Setup Python Virtual Environment**
```bash
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

**Step 5: Configure Environment**
```bash
cp .env.example .env
nano .env
# Add your Firebase credentials
```

**Step 6: Start Service**
```bash
sudo systemctl start news-genesis-scraper
sudo systemctl status news-genesis-scraper
```

---

## 📱 Features & Services

### 1. **Live Streaming (HLS/m3u8)**
- Al Jazeera English & Arabic streams
- Automatic quality selection (720p/480p/360p)
- Network-aware adaptation

### 2. **AI Dubbing (Gemini API)**
- Real-time translation (Malayalam, Hindi, Urdu)
- Multi-language TTS
- Context-aware translation

### 3. **Advanced Audio Processing**
- Speaker diarization
- Multi-voice synthesis
- 5-10 second audio sync precision

### 4. **Firebase Realtime Database**
- Real-time news updates
- Cloud storage for audio/images
- View count tracking

### 5. **Google AdMob (Monetization)**
- Banner ads
- Interstitial ads
- Rewarded ads
- Middle East targeting

### 6. **VPS 24/7 Web Scraper**
- Automated news scraping (every 6 hours)
- Multi-threaded scraping
- Firebase integration

---

## 🔧 Configuration

### Add Credentials
1. **Firebase**: Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
2. **Gemini API**: Update in `main.dart`
3. **AdMob**: Update Ad Unit IDs in `admob_service.dart`

---

## 📊 Project Structure

```
news_genesis/
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   ├── home_page.dart
│   │   ├── live_stream_screen.dart
│   │   └── dubbing_control_panel.dart
│   └── services/
│       ├── hls_stream_service.dart
│       ├── ai_dubbing_service.dart
│       ├── advanced_audio_service.dart
│       ├── firebase_news_service.dart
│       └── admob_service.dart
├── vps_scraper/
│   ├── main.py
│   ├── requirements.txt
│   └── .env.example
├── android/
├── ios/
└── pubspec.yaml
```

---

## 🆘 Support & Resources

- **Firebase**: https://firebase.google.com/docs
- **Gemini API**: https://ai.google.dev/
- **Google AdMob**: https://support.google.com/admob
- **HLS Streaming**: https://developer.apple.com/streaming/

---

**Last Updated**: March 27, 2026  
**Version**: 1.0.0  
**Status**: Production Ready ✅
