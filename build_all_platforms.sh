#!/bin/bash
# News Genesis - Multi-Platform Build Script

echo "🚀 News Genesis - Multi-Platform Builder"
echo "=========================================="
echo ""
echo "Select platform to build:"
echo "1) Web (Chrome/Firefox)"
echo "2) iOS (iPhone/iPad)"
echo "3) macOS (Mac App)"
echo "4) Windows (Win32)"
echo "5) Android (APK)"
echo "6) Android (App Bundle)"
echo "7) Build All (Release)"
echo "8) Clean All"
echo ""
read -p "Enter choice (1-8): " choice

cd /Users/mohammedibrahimkommachikalathil/news_genesis

case $choice in
    1)
        echo "🌐 Building Web..."
        flutter build web --release
        echo "✅ Web build complete: build/web/"
        ;;
    2)
        echo "📱 Building iOS..."
        flutter build ios --release
        echo "✅ iOS build complete: build/ios/ipa/"
        ;;
    3)
        echo "🍎 Building macOS..."
        flutter build macos --release
        echo "✅ macOS build complete: build/macos/Build/Products/Release/"
        ;;
    4)
        echo "🪟 Building Windows..."
        flutter build windows --release
        echo "✅ Windows build complete: build/windows/runner/Release/"
        ;;
    5)
        echo "🤖 Building Android APK..."
        flutter build apk --release
        echo "✅ Android APK complete: build/app/outputs/flutter-apk/"
        ;;
    6)
        echo "🤖 Building Android App Bundle..."
        flutter build appbundle --release
        echo "✅ Android App Bundle complete: build/app/outputs/bundle/"
        ;;
    7)
        echo "🔨 Building all platforms in release mode..."
        echo ""
        
        echo "1/5 Building Web..."
        flutter build web --release
        echo "✅ Web complete"
        echo ""
        
        echo "2/5 Building iOS..."
        flutter build ios --release
        echo "✅ iOS complete"
        echo ""
        
        echo "3/5 Building macOS..."
        flutter build macos --release
        echo "✅ macOS complete"
        echo ""
        
        echo "4/5 Building Windows..."
        flutter build windows --release
        echo "✅ Windows complete"
        echo ""
        
        echo "5/5 Building Android..."
        flutter build apk --release
        flutter build appbundle --release
        echo "✅ Android complete"
        echo ""
        echo "🎉 All platforms built successfully!"
        ;;
    8)
        echo "🧹 Cleaning project..."
        flutter clean
        rm -rf build/
        flutter pub get
        echo "✅ Project cleaned"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "📚 For detailed instructions, see: PLATFORM_SETUP.md"
