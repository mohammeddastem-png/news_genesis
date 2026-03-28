import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  Future<void> prepareVoice(String languageCode) async {
    await _tts.stop();
    await _tts.setLanguage(languageCode);
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
  }

  Future<void> speak({
    required String text,
    required String languageCode,
  }) async {
    await _tts.stop();
    await _tts.setLanguage(languageCode);
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  /// Waits until the engine reports playback finished (web may still vary).
  Future<void> speakUntilComplete({
    required String text,
    required String languageCode,
  }) async {
    await prepareVoice(languageCode);
    final done = Completer<void>();
    void onComplete() {
      if (!done.isCompleted) done.complete();
    }

    _tts.setCompletionHandler(onComplete);
    _tts.setErrorHandler((msg) {
      if (!done.isCompleted) done.complete();
    });
    await _tts.speak(text);
    await done.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () {},
    );
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
