/// Compile-time configuration (pass values with `--dart-define=KEY=value`).
abstract final class AppConfig {
  /// Google AI Studio / Gemini API key. **Do not commit real keys.**
  ///
  /// Example:
  /// `flutter run --dart-define=GEMINI_API_KEY=your_key`
  ///
  /// CI / release: pass the same define in your build pipeline or IDE run configuration.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Model for headline translation (AIService).
  /// `gemini-1.5-flash` is no longer available on the current Generative Language API.
  static const String geminiModelPro = String.fromEnvironment(
    'GEMINI_MODEL_PRO',
    defaultValue: 'gemini-2.5-flash',
  );

  /// Model for dubbing / streaming translation (AIDubbingService).
  static const String geminiModelFlash = String.fromEnvironment(
    'GEMINI_MODEL_FLASH',
    defaultValue: 'gemini-2.5-flash',
  );

  static bool get hasGeminiApiKey => geminiApiKey.isNotEmpty;
}
