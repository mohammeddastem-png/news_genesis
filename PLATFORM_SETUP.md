# News Genesis - Multi-Platform Setup Guide

## 🌍 Supported Platforms
- ✅ **Web** (Chrome, Firefox, Safari)
- ✅ **iOS** (12.0+)
- ✅ **macOS** (10.15+)
- ✅ **Windows** (10+)
- ✅ **Android** (API 21+)

---

## 🚀 Platform-Specific Build Instructions

### 1️⃣ **WEB** (Chrome/Firefox/Safari)

**Prerequisites:**
- Chrome, Firefox, or Safari browser
- Flutter Web enabled: `flutter config --enable-web`

**Build & Run:**
```bash
# Development mode
flutter run -d chrome

# Release build for web
flutter build web --release

# Deploy to web server (after build)
# Output: build/web/
```

**Features on Web:**
- ✅ Live streaming (HLS/M3U8)
- ✅ AI Dubbing (Gemini API)
- ✅ Firebase integration
- ✅ Responsive UI
- ⚠️ Limited audio recording (browser permission required)

---

### 2️⃣ **iOS** (iPad/iPhone)

**Prerequisites:**
- macOS with Xcode installed: `xcode-select --install`
- iOS 12.0+
- Apple Developer account (for App Store deployment)

**Configuration:**
- Minimum SDK: **iOS 12.0**
- Supported orientations: Portrait & Landscape
- Required permissions: Microphone, Camera

**Build & Run:**

```bash
# Connect iPhone via USB
flutter devices  # Verify device appears

# Development mode
flutter run -d ios

# Build IPA for App Store
flutter build ios --release

# Build IPA for distribution
cd ios && pod install && cd ..
flutter build ios --release --obfuscate --split-debug-info=./build/ios/debug
```

**App Permissions** (configured in `ios/Runner/Info.plist`):
- 🎤 Microphone: For audio dubbing & speaker detection
- 📹 Camera: For future video features
- 🌐 Network: For streaming content

**Features on iOS:**
- ✅ Full offline support
- ✅ Native performance for video playback
- ✅ Firebase Cloud Messaging ready
- ✅ AdMob monetization
- ✅ Audio recording & processing

---

### 3️⃣ **macOS** (Mac App)

**Prerequisites:**
- macOS 10.15 or later
- Xcode installed
- Apple Developer account (for distribution)

**Configuration:**
- Minimum SDK: **macOS 10.15**
- Architecture: **Arm64 + Intel x86_64** (universal binary)

**Build & Run:**

```bash
# Connect to Mac (local development)
flutter run -d macos

# Create Release DMG
flutter build macos --release

# Create signed DMG for App Store
flutter build macos --release --codesign
```

**Features on macOS:**
- ✅ Desktop-class performance
- ✅ Multi-window support
- ✅ Full keyboard shortcuts
- ✅ High-resolution display support
- ✅ Native macOS UI integration

---

### 4️⃣ **Windows** (Win32 Desktop)

**Prerequisites:**
- Windows 10 or later
- Visual Studio 2022 with C++ build tools
- Or: MinGW-w64 toolchain

**Configuration:**
- Minimum SDK: **Windows 10**
- Architecture: **x86_64**

**Build & Run:**

```bash
# Verify Windows device support
flutter config --enable-windows-desktop

# Connect to Windows machine
flutter devices

# Development mode
flutter run -d windows

# Create Release EXE
flutter build windows --release

# Output: build/windows/runner/Release/news_genesis.exe
```

**Installation on Target Windows PC:**
```bash
# Copy build/windows/runner/Release/ folder to target machine
# Or create MSIX package:
flutter pub add msix
flutter pub run msix:create
```

**Features on Windows:**
- ✅ Native Windows aesthetic
- ✅ High DPI support
- ✅ Keyboard & mouse support
- ✅ File system integration
- ✅ Direct3D rendering

---

### 5️⃣ **Android** (Phone/Tablet)

**Prerequisites:**
- Android Studio with Android SDK
- Android API 21+ (for video & ads)
- Android device or emulator

**Configuration:**
- Minimum SDK: **API 21** (Android 5.0+)
- Target SDK: **Latest available**

**Build & Run:**

```bash
# List connected Android devices
flutter devices

# Development mode
flutter run -d android

# Create Release APK
flutter build apk --release

# Create App Bundle (for Play Store)
flutter build appbundle --release

# Clean build if issues occur
flutter clean
flutter pub get
flutter build apk --release
```

**Installation on Device:**
```bash
# Direct installation
flutter install --release

# Or manual APK install
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

**Features on Android:**
- ✅ Full offline support
- ✅ Firebase Cloud Messaging
- ✅ Google AdMob integration
- ✅ Speaker diarization via APIs
- ✅ Multi-language support

---

## 📦 Cross-Platform Dependencies

### Core Dependencies (All Platforms)
```yaml
firebase_core        # Backend database
firebase_database    # Realtime data
firebase_storage     # Cloud storage
video_player         # HLS streaming
google_mobile_ads    # Monetization
provider             # State management
http                 # API calls
intl                 # Localization
```

### Platform-Specific Dependencies
```yaml
# iOS/Android Only
audio_session        # Audio configuration
record              # Audio recording
google_mobile_ads   # Ads

# iOS Only (if needed)
device_info_plus    # Device info

# macOS/Windows Only (if needed)
window_manager      # Window control
desktop_window      # Desktop utilities
```

### Web-Specific Support
```yaml
universal_html      # Cross-browser compatibility
```

---

## 🔧 Platform-Specific Configuration

### Firebase Console Setup (All Platforms)
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project: "News Genesis"
3. Add apps for each platform:
   - iOS: Download `GoogleService-Info.plist`
   - Android: Download `google-services.json`
   - Web: Get config from project settings

### iOS Firebase Configuration
```bash
# Place GoogleService-Info.plist in:
ios/Runner/GoogleService-Info.plist

# Also add to Xcode:
# Runner > Build Phases > Copy Bundle Resources
```

### Android Firebase Configuration
```bash
# Place google-services.json in:
android/app/google-services.json
```

### Web Firebase Configuration
```dart
// Already in lib/main.dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    projectId: 'YOUR_PROJECT_ID',
    // ... other config
  ),
);
```

---

## 🎯 Build Commands Summary

```bash
# Clean build across all platforms
flutter clean && flutter pub get

# Build all platforms for release
flutter build web --release      # Web
flutter build ios --release      # iOS
flutter build macos --release    # macOS
flutter build windows --release   # Windows
flutter build apk --release      # Android APK
flutter build appbundle --release # Android App Bundle

# Run on specific device/platform
flutter run -d chrome            # Web
flutter run -d ios              # iOS
flutter run -d macos            # macOS
flutter run -d windows          # Windows
flutter run -d android          # Android
```

---

## 📊 Platform Feature Matrix

| Feature | Web | iOS | macOS | Windows | Android |
|---------|-----|-----|-------|---------|---------|
| **Live Streaming** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **AI Dubbing** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Firebase** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **AdMob Ads** | ⚠️ | ✅ | ⚠️ | ⚠️ | ✅ |
| **Audio Recording** | ⚠️ | ✅ | ✅ | ✅ | ✅ |
| **Offline Mode** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Push Notifications** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Video Picking** | ⚠️ | ✅ | ✅ | ✅ | ✅ |

---

## 🐛 Troubleshooting

### Web Issues
```bash
# Clear old web build
rm -rf build/web
flutter clean

# Run in release mode
flutter run -d chrome --release
```

### iOS Issues
```bash
# Pod dependency issues
cd ios && pod deintegrate && pod install && cd ..

# Build cache issues
flutter clean
rm -rf ios/Pods ios/Podfile.lock
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
# Visual Studio not found
flutter config --windows-sdk-path "C:\Program Files\Microsoft Visual Studio\2022\Community"

# Clean build
flutter clean
flutter pub get
flutter build windows --release
```

### Android Issues
```bash
# SDK version issues
flutter doctor -v

# Gradle issues
cd android && ./gradlew clean && cd ..
flutter clean
flutter pub get
flutter build apk --release
```

---

## 📱 Deployment Checklist

### Before Release
- [ ] Test on all 5 platforms
- [ ] Update version in pubspec.yaml
- [ ] Update Firebase credentials for each platform
- [ ] Register app IDs in Firebase Console
- [ ] Add AdMob app/ad unit IDs
- [ ] Test offline functionality
- [ ] Verify all permissions are documented
- [ ] Test deep linking (if applicable)

### iOS App Store
- [ ] Code sign with Apple Developer certificate
- [ ] Create new app in App Store Connect
- [ ] Add screenshots (iPhone 6.5" & iPad 12.9")
- [ ] Write compelling description
- [ ] Set privacy policy URL
- [ ] Build and upload via Xcode or Fastlane

### Google Play Store
- [ ] Create app bundle (`flutter build appbundle`)
- [ ] Create new app in Google Play Console
- [ ] Add 5+ screenshots
- [ ] Add app description & privacy policy
- [ ] Upload app bundle
- [ ] Configure content rating

### Windows/macOS
- [ ] Create installer (optional)
- [ ] Sign executables
- [ ] Test on clean machines
- [ ] Provide installation instructions

---

## 📞 Support Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Flutter Setup](https://firebase.flutter.dev)
- [Google Mobile Ads SDK](https://developers.google.com/admob)
- [Video Player Plugin](https://pub.dev/packages/video_player)
- [Flutter Community](https://discord.gg/Fwk5vw7N)

---

**Last Updated:** March 2026
**Target Flutter Version:** 3.11.1+
**Target Dart Version:** 3.11.1+
