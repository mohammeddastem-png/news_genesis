# News Genesis - സെറ്റআപ് ചെക്ക്‌ലിസ്റ്റ്

## ✅ സാധാരണ ചെക്ക്‌ലിസ്റ്റ്

### Flutter App ഇൻസ്റ്റലേഷൻ
- [ ] `flutter pub get` പ്രവർത്തിപ്പിച്ചു
- [ ] Google Play Services ഇൻസ്റ്റാൾ ചെയ്തു (Android)
- [ ] Firebase certificates ജോട്ടുചെയ്തു
- [ ] AdMob Ad Unit IDs അപ്ഡേറ്റ് ചെയ്തു
- [ ] Gemini API key കൂട്ടിച്ചേർത്തു

### Firebase Setup
- [ ] Firebase console project സൃഷ്ടിച്ചു
- [ ] Realtime Database സജ്ജമാക്കിയ (മലയാളം: ഡാറ്റാബേസ്)
- [ ] Storage bucket സജ്ജമാക്കിയ
- [ ] Security rules കോൺഫിഗർ ചെയ്തു
- [ ] google-services.json ഡൌൺലോഡ് ചെയ്തു

### Google AdMob Setup
- [ ] AdMob account സൃഷ്ടിച്ചു
- [ ] App രജിസ്റ്റർ ചെയ്തു
- [ ] Banner ad unit സൃഷ്ടിച്ചു
- [ ] Interstitial ad unit സൃഷ്ടിച്ചു
- [ ] Rewarded ad unit സൃഷ്ടിച്ചു

### VPS Setup (Ubuntu/Debian)
- [ ] SSH കീ സെറ്റഅപ് ചെയ്തു
- [ ] Python 3.11+ ഇൻസ്റ്റാൾ ചെയ്തു
- [ ] Firebase credentials കോപ്പി ചെയ്തു
- [ ] Systemd service സൃഷ്ടിച്ചു
- [ ] Firewall configure ചെയ്തു (port 8000)

### API Keys & Credentials
- [ ] 🔐 Gemini API key: `_________________________________`
- [ ] 🔐 Firebase Project ID: `_________________________________`
- [ ] 🔐 AdMob App ID: `_________________________________`
- [ ] 🔐 VPS IP Address: `_________________________________`

---

## 🔧 നിർദ്ദേശങ്ങൾ

### 1️⃣ Flutter App വിന്യാസം
```bash
cd /Users/mohammedibrahimkommachikalathil/news_genesis

# ആഗ്ലോ ഡെപെൻഡെൻസിജ് ലോഡ്
flutter pub get

# iOS നിർമ്മാണ്
flutter run -d ios

# Android നിർമ്മാണ്
flutter run -d android
```

### 2️⃣ VPS Scraper ഇനിയാൻ്‌വിയെ
```bash
# VPS-ൽ കണക്റ്റ്
ssh root@your_vps_ip

# പ്രോജെക്റ് ക്ലോൺ ചെയ്യുക
git clone https://github.com/yourusername/news_genesis.git
cd news_genesis/vps_scraper

# Virtual environment
python3 -m venv venv
source venv/bin/activate

# Dependencies ഇൻസ്റ്റാൾ
pip install -r requirements.txt

# .env ഫയൽ ക്രീയ്റ്റ് ഊഹ
cp .env.example .env
nano .env

# Service സ്റ്റാർട്ട്
sudo systemctl start news-genesis-scraper
sudo systemctl status news-genesis-scraper
```

### 3️⃣ Testing മലയാളം
```bash
# Health check
curl http://your_vps_ip:8000/health

# Scraping trigger
curl -X POST http://your_vps_ip:8000/scrape?channel=english

# Logs ചെക്ക്
sudo journalctl -u news-genesis-scraper -f
```

---

## 📋 കോൺഫിഗ്യുരേഷൻ ഫയൽ ചെക്ക്‌ലിസ്റ്റ്

| ഫയൽ | സ്ഥാനം | നിർദ്ദേശം |
|------|--------|---------|
| google-services.json | `android/app/` | Firebase project നിന്ന് ഡൌൺലോഡ് |
| GoogleService-Info.plist | `ios/Runner/` | Firebase project നിന്ന് ഡൌൺലോഡ് |
| .env | `vps_scraper/` | Firebase credentials ചേർക്കുക |
| firebase-credentials.json | `vps_scraper/` | Firebase Admin SDK key |
| main.dart | `lib/` | Gemini API key അപ്ഡേറ്റ് |
| admob_service.dart | `lib/services/` | Ad Unit IDs അപ്ഡേറ്റ് |

---

## ⚠️ പ്രധാന വിപ്പരിച്ചാലായി ഓരുകൾ

- **API Keys**: Never commit സെൻസിറ്റീവ് കീജ് Git-ലേക്ക്
- **Firebase Rules**: Database അപൂർണ്ണ അക്സസ് സ്ക്രീനിടാൻ വിപരീതെ അരിയുക
- **AdMob Setup**: Test IDs ഉപയോഗിക്കുക നിർമ്മാണ സമയത്ത്
- **VPS Security**: Root login നിഷേധ ചെയ്യുക SSH നിയമങ്ങളിൽ
- **Firewall**: Unnecessary ports അലർട്ട് ചെയ്യുക

---

## 🐛 സാധാരണ പ്രശ്നം & പരിഹാരങ്ങൾ

### Video Stream കൊതിമാനൈ പ്ലേയ്ക് ചെയ്യാൻ പാടുന്നില്ല
```
പരിഹാരം:
1. .m3u8 URL validate ചെയ്യുക
2. video_player iOS/Android കമ്പാൻ channel പരിശോധിക്കുക
3. network logs observ ചെയ്യുക
```

### Gemini API Rate Limited
```
പരിഹാരം:
1. Exponential backoff ഉപയോഗിക്കുക
2. Firebase Remote Config നിന്ന് API keys rotate ചെയ്യുക
3. Translation ക്যാച് ഉപയോഗിക്കുക
```

### VPS Scraper നിഷ്ക്രിയം
```
പരിഹാരം:
1. sudo systemctl status news-genesis-scraper
2. journalctl logs പരിശോധിക്കുക
3. Firebase connectivity പരിശോധിക്കുക
```

---

## 📚 അധിക റിസോഴ്സെസ്

- [Firebase Documentation](https://firebase.google.com/docs)
- [Google Gemini API](https://ai.google.dev/)
- [AdMob Help Center](https://support.google.com/admob)
- [Flutter Documentation](https://flutter.dev/docs)

---

## 📞 Support

Questions or issues? ഇനി വരാൻ്നിരിക്കുന്നത് വരാനേ പരാനെ്നെഗാർ്ത്തെ പത്ര്മ്മ്സാംഖ്യ സാഹചര്യ്ത്തിൽ!

---

**Version**: 1.0  
**Updated**: March 27, 2026
