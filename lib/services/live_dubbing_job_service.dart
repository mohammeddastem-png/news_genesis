import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

/// RTDB-ൽ `dubbing_jobs/{jobId}` — GitHub Actions വർക്കർ ഇത് പ്രോസസ്സ് ചെയ്യും.
class LiveDubbingJob {
  LiveDubbingJob({
    required this.jobId,
    required this.status,
    this.sourceEnglish,
    this.translatedText,
    this.audioUrl,
    this.durationSec,
    this.syncSeconds,
    this.errorMessage,
  });

  final String jobId;
  final String status;
  final String? sourceEnglish;
  final String? translatedText;
  final String? audioUrl;
  final double? durationSec;
  final double? syncSeconds;
  final String? errorMessage;

  factory LiveDubbingJob.fromMap(String id, Map<dynamic, dynamic> m) {
    return LiveDubbingJob(
      jobId: id,
      status: '${m['status'] ?? ''}',
      sourceEnglish: m['sourceEnglish'] as String?,
      translatedText: m['translatedText'] as String?,
      audioUrl: m['audioUrl'] as String?,
      durationSec: (m['durationSec'] as num?)?.toDouble(),
      syncSeconds: (m['syncSeconds'] as num?)?.toDouble(),
      errorMessage:
          m['errorMessage'] as String? ?? m['error'] as String?,
    );
  }
}

class LiveDubbingJobService {
  LiveDubbingJobService(this._db);

  final FirebaseDatabase _db;
  static const _uuid = Uuid();

  DatabaseReference get _root => _db.ref('dubbing_jobs');

  /// `sourceEnglish`: സബ്ടൈറ്റിൽ നിന്നോ ക്ലയന്റിൽ നിന്നുള്ള ഇംഗ്ലീഷ് ടെക്സ്റ്റ് (യഥാർത്ഥ STT പിന്നീട് Storage ഓഡിയോയിലൂടെ).
  Future<String> enqueueJob({
    required String sourceEnglish,
    required double syncSeconds,
    required String videoId,
    required String targetLangCode,
    int minAudioSec = 20,
  }) async {
    final jobId = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    await _root.child(jobId).set({
      'status': 'pending',
      'sourceEnglish': sourceEnglish,
      'syncSeconds': syncSeconds,
      'videoId': videoId,
      'targetLangCode': targetLangCode,
      'minAudioSec': minAudioSec,
      'createdAt': now,
    });
    return jobId;
  }

  Stream<LiveDubbingJob?> watchJob(String jobId) {
    return _root.child(jobId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return null;
      }
      final v = event.snapshot.value;
      if (v is! Map<dynamic, dynamic>) return null;
      return LiveDubbingJob.fromMap(jobId, v);
    });
  }
}
