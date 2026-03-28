import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class NewsArticle {
  final String id;
  final String title;
  final String content;
  final String language;
  final String channelType; // 'english' or 'arabic'
  final DateTime createdAt;
  final String imageUrl;
  final int views;
  final bool isDubbed;

  NewsArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.language,
    required this.channelType,
    required this.createdAt,
    required this.imageUrl,
    this.views = 0,
    this.isDubbed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'language': language,
      'channelType': channelType,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
      'views': views,
      'isDubbed': isDubbed,
    };
  }

  factory NewsArticle.fromMap(Map<dynamic, dynamic> map) {
    return NewsArticle(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      language: map['language'] ?? 'en',
      channelType: map['channelType'] ?? 'english',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      imageUrl: map['imageUrl'] ?? '',
      views: map['views'] ?? 0,
      isDubbed: map['isDubbed'] ?? false,
    );
  }
}

class DubbedAudio {
  final String id;
  final String articleId;
  final String language;
  final String audioUrl;
  final Duration duration;
  final DateTime createdAt;

  DubbedAudio({
    required this.id,
    required this.articleId,
    required this.language,
    required this.audioUrl,
    required this.duration,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'articleId': articleId,
      'language': language,
      'audioUrl': audioUrl,
      'duration': duration.inSeconds,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Firebase Realtime Database Service for news content
class FirebaseNewsService {
  FirebaseDatabase? _database;
  final List<NewsArticle> _newsArticles = [];
  final List<DubbedAudio> _dubbedAudios = [];

  List<NewsArticle> get newsArticles => _newsArticles;
  List<DubbedAudio> get dubbedAudios => _dubbedAudios;

  bool get hasDatabase => _database != null;

  FirebaseNewsService() {
    _initializeDatabase();
  }

  void _initializeDatabase() {
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase ഇനിഷ്യലൈസ് ചെയ്തിട്ടില്ല — ഡാറ്റാബേസ് പ്രവർത്തിക്കില്ല');
        return;
      }
      _database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: DefaultFirebaseOptions.databaseUrl,
      );
    } catch (e) {
      debugPrint('Firebase Database ലഭ്യമല്ല: $e');
    }
  }

  /// നിലവിലെ ന്യൂസ് ലോഡ് ചെയ്യുക
  Future<void> fetchLatestNews({
    String channelType = 'english',
    String language = 'en',
    int limit = 20,
  }) async {
    try {
      final db = _database;
      if (db == null) return;
      final ref = db.ref('news/$channelType');

      final snapshot = await ref
          .orderByChild('createdAt')
          .limitToLast(limit)
          .get();

      _newsArticles.clear();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          _newsArticles.add(NewsArticle.fromMap(value));
        });
      }

      // Sort in reverse order (newest first)
      _newsArticles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error fetching news: $e');
    }
  }

  /// സിംഗിൾ ന്യൂസ് ആർട്സ്കെൽ ലോഡ്
  Future<NewsArticle?> fetchNewsById({
    required String channelType,
    required String articleId,
  }) async {
    try {
      final db = _database;
      if (db == null) return null;
      final ref = db.ref('news/$channelType/$articleId');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        return NewsArticle.fromMap(snapshot.value as Map<dynamic, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching article: $e');
      return null;
    }
  }

  /// ന്യൂസ് ആർട്സ്കെൾ സേവ് ചെയ്യുക (ബാക്ക്എൻഡ് സ്ക്രാപറിൽ നിന്ന്)
  Future<void> saveNewsArticle(NewsArticle article) async {
    try {
      final db = _database;
      if (db == null) return;
      final ref = db.ref('news/${article.channelType}/${article.id}');
      await ref.set(article.toMap());
      debugPrint('Article saved: ${article.id}');
    } catch (e) {
      debugPrint('Error saving article: $e');
    }
  }

  /// Upload dubbed audio to cloud storage
  Future<String> uploadDubbedAudio(
    String audioFilePath,
    String articleId,
    String language,
  ) async {
    try {
      // Mock cloud upload - in production, handle via VPS backend
      final mockDownloadUrl = 'https://storage.example.com/dubbed_audio/${articleId}_$language.mp3';

      // Save to database with mock URL
      final dubbedAudio = DubbedAudio(
        id: '${articleId}_$language',
        articleId: articleId,
        language: language,
        audioUrl: mockDownloadUrl,
        duration: const Duration(seconds: 0),
        createdAt: DateTime.now(),
      );

      await saveDubbedAudio(dubbedAudio);
      return mockDownloadUrl;
    } catch (e) {
      debugPrint('Error uploading dubbed audio: $e');
      rethrow;
    }
  }

  /// ഡബ്ബ്ബഡ് ആഡിയോ ഡാറ്റാബേസിൽ സേവ് ചെയ്യുക
  Future<void> saveDubbedAudio(DubbedAudio dubbedAudio) async {
    try {
      final db = _database;
      if (db == null) return;
      final ref = db.ref(
          'dubbed_audio/${dubbedAudio.articleId}/${dubbedAudio.language}');
      await ref.set(dubbedAudio.toMap());
      debugPrint('Dubbed audio saved: ${dubbedAudio.id}');
    } catch (e) {
      debugPrint('Error saving dubbed audio: $e');
    }
  }

  /// Increment article view count
  Future<void> incrementViewCount({
    required String channelType,
    required String articleId,
  }) async {
    try {
      final db = _database;
      if (db == null) return;
      final ref = db.ref('news/$channelType/$articleId/views');
      await ref.runTransaction((value) {
        final current = (value is int) ? value : int.tryParse('$value') ?? 0;
        return Transaction.success(current + 1);
      });
      debugPrint('View count incremented for: $articleId');
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  /// ലൈവ് അപ്ഡേറ്റ് ലിസ്റ്റനർ സെട് ചെയ്യുക ( Screenshots നിന്ന്)
  Stream<List<NewsArticle>> watchLatestNews(String channelType) {
    final db = _database;
    if (db == null) {
      return Stream.value(<NewsArticle>[]);
    }
    return db.ref('news/$channelType').onValue.map((event) {
      List<NewsArticle> articles = [];
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          articles.add(NewsArticle.fromMap(value));
        });
        articles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return articles;
    });
  }

  /// വിവിധ ഭാഷകളിൽ ന്യൂസ് തിരയുക
  Future<List<NewsArticle>> searchNews(
    String query, {
    String language = 'en',
  }) async {
    try {
      final db = _database;
      if (db == null) return [];
      final ref = db.ref('news');
      final snapshot = await ref.get();

      List<NewsArticle> results = [];

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, channelData) {
          if (channelData is Map<dynamic, dynamic>) {
            channelData.forEach((articleKey, articleData) {
              if (articleData is Map<dynamic, dynamic>) {
                final article = NewsArticle.fromMap(articleData);
                if (article.title.toLowerCase().contains(query.toLowerCase()) ||
                    article.content
                        .toLowerCase()
                        .contains(query.toLowerCase())) {
                  results.add(article);
                }
              }
            });
          }
        });
      }

      return results;
    } catch (e) {
      debugPrint('Error searching news: $e');
      return [];
    }
  }
}
