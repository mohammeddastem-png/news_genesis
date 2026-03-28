import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/app_config.dart';
import 'firebase_news_service.dart';

class TranslatedHeadline {
  final String malayalam;
  final String hindi;

  const TranslatedHeadline({
    required this.malayalam,
    required this.hindi,
  });
}

class AIService {
  final GenerativeModel _model;

  AIService({required String apiKey})
      : _model = GenerativeModel(
          model: AppConfig.geminiModelPro,
          apiKey: apiKey,
        );

  Future<TranslatedHeadline> translateTitle(String title) async {
    final prompt = '''
Translate this news headline to Malayalam and Hindi.
Keep the translation short and natural for a mobile news app.
Return JSON only in this format:
{"ml":"...","hi":"..."}

Headline:
$title
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final output = response.text?.trim() ?? '';

    final parsed = _parseTranslatedJson(output);
    if (parsed != null) {
      return parsed;
    }

    return TranslatedHeadline(
      malayalam: _extractValue(output, 'ml'),
      hindi: _extractValue(output, 'hi'),
    );
  }

  /// Strips optional ```json fences and parses JSON so Malayalam script parses reliably.
  TranslatedHeadline? _parseTranslatedJson(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s.replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '');
      s = s.replaceFirst(RegExp(r'\s*```\s*$'), '');
      s = s.trim();
    }
    try {
      final decoded = jsonDecode(s);
      if (decoded is! Map) return null;
      final ml = decoded['ml'];
      final hi = decoded['hi'];
      if (ml is! String || hi is! String) return null;
      return TranslatedHeadline(malayalam: ml, hindi: hi);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, TranslatedHeadline>> translateArticles(
    List<NewsArticle> articles,
  ) async {
    final result = <String, TranslatedHeadline>{};
    for (final article in articles) {
      try {
        result[article.id] = await translateTitle(article.title);
      } catch (_) {
        result[article.id] = const TranslatedHeadline(
          malayalam: 'പരിഭാഷ ലഭ്യമല്ല',
          hindi: 'अनुवाद उपलब्ध नहीं है',
        );
      }
    }
    return result;
  }

  String _extractValue(String jsonLike, String key) {
    final regex = RegExp('"$key"\\s*:\\s*"([^"]*)"');
    final match = regex.firstMatch(jsonLike);
    if (match != null && match.groupCount >= 1) {
      return match.group(1) ?? '';
    }
    return '';
  }
}
