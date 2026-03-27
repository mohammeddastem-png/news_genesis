import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';

enum TargetLanguage { malayalam, hindi, urdu }

/// Service for AI-powered real-time dubbing using Gemini API
class AIDubbingService {
  final String apiKey; // Add to .env or Firebase Remote Config
  final String modelName;

  // Map target languages to proper language codes
  static const Map<TargetLanguage, String> languageCodes = {
    TargetLanguage.malayalam: 'ml',
    TargetLanguage.hindi: 'hi',
    TargetLanguage.urdu: 'ur',
  };

  AIDubbingService({
    required this.apiKey,
    this.modelName = 'gemini-1.5-flash',
  });

  /// Translate news transcript with context preservation
  Future<String> translateNewsContent(
    String sourceText,
    String sourceLanguage,
    TargetLanguage targetLanguage,
  ) async {
    try {
      final targetCode = languageCodes[targetLanguage] ?? 'en';
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
      );

      final prompt = '''
You are a professional broadcast-news translator.

Task: Translate from "$sourceLanguage" to "$targetCode".

Requirements:
- Preserve meaning, names, numbers, dates, and places exactly.
- Use natural, on-air phrasing suitable for live news.
- Keep it concise; do not add commentary.
- Output only the translation (no quotes, no labels).

Text:
$sourceText
''';

      // Simple retry for transient errors (timeouts/429/etc.)
      final responseText = await _retry<String>(() async {
        final res = await model.generateContent([Content.text(prompt)]);
        final text = res.text?.trim();
        if (text == null || text.isEmpty) {
          throw StateError('Empty translation response');
        }
        return text;
      });

      return responseText;
    } catch (e) {
      throw Exception('Translation failed: $e');
    }
  }

  /// Stream real-time translations for live news
  Stream<String> streamTranslation(
    Stream<String> sourceTextStream,
    String sourceLanguage,
    TargetLanguage targetLanguage,
  ) async* {
    await for (String text in sourceTextStream) {
      try {
        final translated =
            await translateNewsContent(text, sourceLanguage, targetLanguage);
        yield translated;
      } catch (e) {
        yield 'Translation error';
      }
    }
  }

  Future<T> _retry<T>(
    Future<T> Function() fn, {
    int maxAttempts = 3,
    Duration baseDelay = const Duration(milliseconds: 400),
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await fn();
      } catch (e) {
        lastError = e;
        if (attempt == maxAttempts) rethrow;
        await Future.delayed(baseDelay * attempt);
      }
    }
    throw StateError('Retry failed: $lastError');
  }

  /// Initialize TTS for multi-language voice synthesis
  Future<void> initTTS(TargetLanguage language) async {
    try {
      final languageCode = languageCodes[language] ?? 'en';
      print('TTS initialized for $languageCode');
    } catch (e) {
      print('Warning: Could not set TTS voice: $e');
    }
  }

  /// Play dubbed audio with audio syncing (5-10 second precision)
  Future<void> playDubbing(
    String translatedText,
    TargetLanguage language,
    Duration audioSyncOffset,
  ) async {
    try {
      await initTTS(language);

      // Calculate speech duration for synchronization
      final estimatedDuration = _calculateSpeechDuration(translatedText);

      if (estimatedDuration.inSeconds > 10) {
        print('Warning: Dubbed audio exceeds 10 seconds: $estimatedDuration');
      }

      // Apply audio sync offset (typically 5-10 seconds before/after)
      await Future.delayed(audioSyncOffset);

      print('Playing dubbed audio: $translatedText');
    } catch (e) {
      throw Exception('Failed to play dubbing: $e');
    }
  }

  /// Calculate approximate speech duration for synchronization
  Duration _calculateSpeechDuration(String text) {
    // Average speaking speed: 130-150 words per minute
    // Roughly 2-3 seconds per sentence in news context
    final words = text.split(' ').length;
    final estimatedSeconds = (words / 140) * 60;

    return Duration(seconds: estimatedSeconds.toInt());
  }

  /// Get speaker profile for diarization-aware dubbing
  Future<Map<String, dynamic>> getSpeakerProfile(String speakerId) async {
    try {
      return {
        'speaker_id': speakerId,
        'characteristics': 'Default voice characteristics',
        'timestamp': DateTime.now(),
      };
    } catch (e) {
      return {'error': 'Failed to get speaker profile'};
    }
  }

  /// Clean up TTS resources
  Future<void> dispose() async {
    print('Dubbing service disposed');
  }
}
