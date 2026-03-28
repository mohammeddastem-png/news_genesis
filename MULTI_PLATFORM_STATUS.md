# News Genesis - Multi-Platform Configuration Summary

## ✅ Platforms Configured

### 1. **WEB** ✓ (Ready to run)
- Path: `web/`
- Runtime: Chrome, Firefox, Safari
- Command: `flutter run -d chrome`
- Features: Full UI, streaming, dubbing
- Build: `flutter build web --release`

### 2. **iOS** ✓ (Ready to build)
- Path: `ios/`
- Min Version: iOS 12.0+
- Permissions Added:
  - 🎤 Microphone (dubbing, speaker detection)
  - 📹 Camera (future features)
  - 🌐 Local network (streaming)
- Command: `flutter run -d ios`
- Build: `flutter build ios --release`
- Output: `.ipa` file for App Store

### 3. **macOS** ✓ (Ready to build)
- Path: `macos/`
- Min Version: macOS 10.15+
- Architecture: Universal (Arm64 + x86_64)
- Command: `flutter run -d macos`
- Build: `flutter build macos --release`
- Output: `.app` bundle or `.dmg` installer

### 4. **WINDOWS** ✓ (Ready to build)
- Path: `windows/`
- Min Version: Windows 10+
- Architecture: x86_64
- Command: `flutter run -d windows`
- Build: `flutter build windows --release`
- Output: `.exe` standalone application

### 5. **ANDROID** ✓ (Ready to build)
- Path: `android/`
- Min Version: API 21 (Android 5.0+)
- Command: `flutter run -d android`
- Build APK: `flutter build apk --release`
- Build Bundle: `flutter build appbundle --release`
- Output: `.apk` and `.aab` for Play Store

---

## 📦 Dependencies for All Platforms

```yaml
# Core (All platforms)
firebase_core          # Firebase backend
firebase_database      # Realtime database
firebase_storage       # Cloud storage
video_player           # HLS/M3U8 streaming
google_mobile_ads      # Monetization
provider               # State management
http                   # Network requests
intl                   # Internationalization

# Mobile (iOS + Android)
audio_session          # Audio configuration
record                 # Audio recording
google_mobile_ads      # Mobile ads

# Web Support
universal_html         # Cross-browser compatibility
```

---

## 🎯 Platform Feature Status

| Feature | Web | iOS | macOS | Windows | Android |
|---------|-----|-----|-------|---------|---------|
| Live Streaming (HLS) | ✅ | ✅ | ✅ | ✅ | ✅ |
| AI Dubbing (Gemini) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Firebase DB | ✅ | ✅ | ✅ | ✅ | ✅ |
| Audio Recording | ⚠️ | ✅ | ✅ | ✅ | ✅ |
| Speaker Detection | ⚠️ | ✅ | ✅ | ✅ | ✅ |
| AdMob Ads | ⚠️ | ✅ | ⚠️ | ⚠️ | ✅ |
| Offline Mode | ✅ | ✅ | ✅ | ✅ | ✅ |

**Legend:** ✅ = Full Support | ⚠️ = Partial/Limited | ❌ = Not Available

---

## 🔨 Quick Build Commands

```bash
# Clean everything
flutter clean && flutter pub get

# Run on each platform
flutter run -d chrome        # Web
flutter run -d ios          # iOS
flutter run -d macos        # macOS
flutter run -d windows      # Windows
flutter run -d android      # Android

# Build releases
flutter build web --release       # Web
flutter build ios --release       # iOS
flutter build macos --release     # macOS
flutter build windows --release   # Windows
flutter build apk --release       # Android APK
flutter build appbundle --release # Android Bundle
```

---

## 📱 Installation Methods by Platform

### **Web**
```bash
# Development
flutter run -d chrome

# Production deploy
flutter build web --release
# Upload build/web/ to web hosting (Firebase Hosting, Netlify, Vercel)
```

### **iOS**
```bash
# Development on connected iPhone
flutter run -d ios

# Build for App Store
flutter build ios --release
# Open in Xcode and upload to App Store Connect
open ios/Runner.xcworkspace
```

### **macOS**
```bash
# Development on Mac
flutter run -d macos

# Build DMG installer
flutter build macos --release
# Output: build/macos/Build/Products/Release/
```

### **Windows**
```bash
# Development on Windows PC
flutter run -d windows

# Build standalone EXE
flutter build windows --release
# Output: build/windows/runner/Release/news_genesis.exe
# Distribute or create MSIX installer
```

### **Android**
```bash
# Development on connected device
flutter run -d android

# Build APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Build App Bundle for Play Store
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## 🚀 Deployment Workflows

### **App Store (iOS)**
```
1. flutter build ios --release
2. Open ios/Runner.xcworkspace in Xcode
3. Set signing team and bundle ID
4. Create archive
5. Upload via App Store Connect or Xcode
```

### **Google Play (Android)**
```
1. flutter build appbundle --release
2. Upload build/app/outputs/bundle/release/app-release.aab
3. Google Play Console handles architecture splits
```

### **Web Hosting**
```
1. flutter build web --release
2. Deploy build/web/ to:
   - Firebase Hosting: firebase init && firebase deploy
   - Netlify: drag and drop build/web/
   - Vercel: connect GitHub repo
```

### **Windows Store (Optional)**
```
1. flutter pub add msix
2. flutter pub run msix:create
3. Upload to Microsoft Store
```

### **macOS App Store (Optional)**
```
1. flutter build macos --release
2. Create app archive
3. Notarize with Apple
4. Upload to App Store Connect
```

---

## 🔐 Firebase Configuration

### iOS
```
⚠️ REQUIRED: Add GoogleService-Info.plist
1. Firebase Console → Download plist
2. Open ios/Runner.xcworkspace
3. Drag plist into Runner folder
4. Enable "Copy items if needed"
```

### Android
```
⚠️ REQUIRED: Add google-services.json
1. Firebase Console → Download JSON
2. Place in android/app/google-services.json
3. Gradle automatically uses it
```

### Web
```
Already configured in lib/main.dart
Firebase config values are embedded in code
```

### macOS & Windows
```
Same as iOS/Android configuration using native Firebase SDKs
```

---

## 📊 Platform Specifications

### iOS Minimum Requirements
- iOS 12.0+
- Xcode 13.0+
- Apple Developer account

### macOS Minimum Requirements
- macOS 10.15+
- Xcode 13.0+
- Apple Developer account

### Windows Minimum Requirements
- Windows 10 (Build 19041) or later
- Visual Studio 2022 with C++ tools
- No account needed for distribution

### Android Minimum Requirements
- API 21+ (Android 5.0+)
- Google Play account for distribution

### Web Minimum Requirements
- Modern browser (Chrome 90+, Firefox 88+, Safari 14+)
- Standard web hosting

---

## 🛠️ Helper Scripts

### Build All Platforms
```bash
./build_all_platforms.sh
# Interactive menu for selecting platform or "Build All"
```

### Clean & Rebuild
```bash
flutter clean
flutter pub get
flutter build <platform> --release
```

---

## 📞 Troubleshooting by Platform

### iOS Issues
```bash
# Pod issues
cd ios && pod deintegrate && pod install && cd ..

# Xcode issues
rm -rf ios/Pods ios/Podfile.lock
flutter clean
flutter pub get
```

### macOS Issues
```bash
# Similar to iOS
cd macos && pod deintegrate && pod install && cd ..
flutter clean
flutter pub get
```

### Windows Issues
```bash
# Visual Studio setup
flutter config --windows-sdk-path "C:\Program Files\Microsoft Visual Studio\2022\Community"

# Rebuild
flutter clean
flutter pub get
flutter build windows --release
```

### Android Issues
```bash
# Gradle cache
cd android && ./gradlew clean && cd ..

# Full rebuild
flutter clean
flutter pub get
flutter build apk --release
```

### Web Issues
```bash
# Clear web cache
rm -rf build/web
flutter clean

# Rebuild
flutter build web --release
flutter run -d chrome --release
```

---

## ✅ Pre-Release Checklist

- [ ] All platforms run without errors
- [ ] Firebase credentials configured for each platform
- [ ] Update version: `pubspec.yaml`
- [ ] Test on real devices (not just emulators)
- [ ] Test offline functionality
- [ ] Verify all permissions are documented
- [ ] Test on both debug and release builds
- [ ] Check app size (should be < 50MB)
- [ ] Update privacy policy URL
- [ ] Add app store descriptions/screenshots
- [ ] Test on minimum supported OS versions

---

## 📚 Documentation Files

- **PLATFORM_SETUP.md** - Detailed platform setup guide
- **README.md** - Project overview
- **SETUP_CHECKLIST.md** - Initial setup steps
- **API_DOCUMENTATION.md** - API references

---

**Last Updated:** March 28, 2026
**Target Flutter:** 3.11.1+
**Status:** ✅ All Platforms Ready for Development & Deployment
