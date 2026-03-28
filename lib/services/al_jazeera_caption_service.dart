import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Text window derived from YouTube closed captions (proxy for spoken audio).
class CaptionTextWindow {
  CaptionTextWindow({
    required this.englishText,
    required this.startSeconds,
  });

  final String englishText;
  final double startSeconds;
}

/// Fetches recent on-screen captions for a video — closest to “original audio → text” without a server ASR.
class AlJazeeraCaptionService {
  static const Duration _window = Duration(seconds: 90);

  /// Returns the last ~[_window] of caption text and the seek time for its start.
  /// Throws if no usable captions (caller may fall back to AI-generated English).
  static Future<CaptionTextWindow> fetchLatestWindow(String videoId) async {
    final explode = YoutubeExplode();
    try {
      final manifest = await explode.videos.closedCaptions.getManifest(videoId);

      final enTracks = manifest.tracks
          .where((t) => t.language.code.toLowerCase().startsWith('en'))
          .toList();
      ClosedCaptionTrackInfo info;
      if (enTracks.isNotEmpty) {
        info = enTracks.firstWhere(
          (t) => t.format == ClosedCaptionFormat.vtt,
          orElse: () => enTracks.first,
        );
      } else if (manifest.tracks.isNotEmpty) {
        info = manifest.tracks.first;
      } else {
        throw StateError('No caption tracks');
      }

      final track = await explode.videos.closedCaptions.get(info);
      final caps = track.captions;
      if (caps.isEmpty) throw StateError('Empty captions');

      ClosedCaption latest = caps.first;
      for (final c in caps) {
        if (c.end > latest.end) latest = c;
      }

      final windowEnd = latest.end;
      final windowStart = windowEnd - _window;
      final inWindow = caps
          .where((c) => c.end > windowStart && c.offset < windowEnd)
          .toList()
        ..sort((a, b) => a.offset.compareTo(b.offset));

      if (inWindow.isEmpty) throw StateError('No captions in window');

      final text = inWindow.map((c) => c.text.trim()).where((s) => s.isNotEmpty).join(' ');
      if (text.isEmpty) throw StateError('Blank caption text');

      final startSeconds = inWindow.first.offset.inMilliseconds / 1000.0;
      return CaptionTextWindow(
        englishText: text.length > 6000 ? text.substring(0, 6000) : text,
        startSeconds: startSeconds,
      );
    } finally {
      explode.close();
    }
  }
}
