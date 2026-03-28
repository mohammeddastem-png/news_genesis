// ignore_for_file: lines_longer_than_80_chars
// ഫയർബേസ് കൺസോളിൽ Web ആപ്പ് ചേർത്ത് appId ശരിയാക്കുക (FlutterFire CLI: flutterfire configure).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Project: newsgenesis-59790 (google-services.json അടിസ്ഥാനത്തിൽ).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        return android;
    }
  }

  static const String databaseUrl =
      'https://newsgenesis-59790-default-rtdb.firebaseio.com';

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC0D3iDlk_47dB_qTx1cw77ntAKDoEn-s8',
    appId: '1:335256069796:web:news_genesis_placeholder',
    messagingSenderId: '335256069796',
    projectId: 'newsgenesis-59790',
    authDomain: 'newsgenesis-59790.firebaseapp.com',
    databaseURL: databaseUrl,
    storageBucket: 'newsgenesis-59790.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC0D3iDlk_47dB_qTx1cw77ntAKDoEn-s8',
    appId: '1:335256069796:android:97a38eaeca14333de4e831',
    messagingSenderId: '335256069796',
    projectId: 'newsgenesis-59790',
    storageBucket: 'newsgenesis-59790.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC0D3iDlk_47dB_qTx1cw77ntAKDoEn-s8',
    appId: '1:335256069796:ios:news_genesis_placeholder',
    messagingSenderId: '335256069796',
    projectId: 'newsgenesis-59790',
    storageBucket: 'newsgenesis-59790.firebasestorage.app',
    iosBundleId: 'com.example.newsGenesis',
  );
}
