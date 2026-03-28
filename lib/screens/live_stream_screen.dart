import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../config/app_config.dart';
import '../services/ai_dubbing_service.dart';
import '../services/al_jazeera_caption_service.dart';
import '../services/live_dubbing_job_service.dart';

/// അൽ ജസീറ ഇംഗ്ലീഷ് മാത്രം — ക്ലയന്റ് ഇംഗ്ലീഷ് ടെക്സ്റ്റ് RTDB-യിലേക്ക്,
/// GitHub Actions + `dubbing_worker.py` വിവർത്തനം/ഓഡിയോ, തയ്യാറാകുമ്പോൾ വീഡിയോ + റിമോട്ട് MP3.
class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({
    super.key,
    required this.dubbingJobService,
    this.dubbingService,
  });

  final LiveDubbingJobService? dubbingJobService;
  final AIDubbingService? dubbingService;

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  static const String _alJazeeraEnglishLiveId = 'gCNeDWCI0vo';

  late final YoutubePlayerController _yt;
  AudioPlayer? _audioPlayer;
  StreamSubscription<LiveDubbingJob?>? _jobSub;

  bool _dubbingBusy = false;
  String _statusLine = '';

  @override
  void initState() {
    super.initState();
    _yt = YoutubePlayerController.fromVideoId(
      videoId: _alJazeeraEnglishLiveId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        enableCaption: true,
        captionLanguage: 'en',
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void dispose() {
    _jobSub?.cancel();
    final ap = _audioPlayer;
    if (ap != null) {
      unawaited(ap.dispose());
    }
    unawaited(_yt.close());
    super.dispose();
  }

  String _targetLangCode(TargetLanguage l) => switch (l) {
        TargetLanguage.malayalam => 'ml',
        TargetLanguage.tamil => 'ta',
        TargetLanguage.urdu => 'ur',
        TargetLanguage.hindi => 'hi',
      };

  Future<void> _restoreOriginalStream() async {
    await _jobSub?.cancel();
    _jobSub = null;
    await _audioPlayer?.stop();
    await _audioPlayer?.dispose();
    _audioPlayer = null;
    await _yt.unMute();
    await _yt.playVideo();
    if (mounted) {
      setState(() {
        _statusLine = '';
        _dubbingBusy = false;
      });
    }
  }

  Future<void> _runLiveDub(TargetLanguage lang) async {
    final jobs = widget.dubbingJobService;
    if (jobs == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ഫയർബേസ് കണക്റ്റ് ചെയ്യുക. വെബ് ആപ്പ് ഫയർബേസ് കൺസോളിൽ രജിസ്റ്റർ ചെയ്ത് firebase_options.dart പുതുക്കുക.',
          ),
        ),
      );
      return;
    }

    if (_dubbingBusy) return;
    setState(() {
      _dubbingBusy = true;
      _statusLine = 'വീഡിയോ നിർത്തുന്നു…';
    });

    await _jobSub?.cancel();
    _jobSub = null;
    await _audioPlayer?.dispose();
    _audioPlayer = null;

    try {
      await _yt.pauseVideo();
      await _yt.mute();

      setState(() => _statusLine = 'യഥാർത്ഥ ടെക്സ്റ്റ് (സബ്ടൈറ്റിൽ) ശേഖരിക്കുന്നു…');
      String englishText;
      try {
        final w = await AlJazeeraCaptionService.fetchLatestWindow(
          _alJazeeraEnglishLiveId,
        );
        englishText = w.englishText;
      } catch (e) {
        debugPrint('Caption: $e');
        final dub = widget.dubbingService;
        if (dub == null || !AppConfig.hasGeminiApiKey) {
          throw StateError(
            'സബ്ടൈറ്റ് ലഭ്യമല്ല; ക്ലയന്റിൽ Gemini ഇല്ല. GEMINI_API_KEY ചേർക്കുക.',
          );
        }
        setState(() => _statusLine = 'ഇംഗ്ലീഷ് സ്ക്രിപ്റ്റ് (AI ഫോൾബാക്ക്)…');
        englishText = await dub.generateEnglishBroadcastScriptFallback();
      }

      final syncSeconds = await _yt.currentTime;

      setState(() => _statusLine = 'ഫയർബേസിൽ ജോബ് അയയ്ക്കുന്നു… (GitHub worker കാത്തിരിക്കുക)');
      final jobId = await jobs.enqueueJob(
        sourceEnglish: englishText,
        syncSeconds: syncSeconds,
        videoId: _alJazeeraEnglishLiveId,
        targetLangCode: _targetLangCode(lang),
        minAudioSec: 20,
      );

      var handled = false;
      _jobSub = jobs.watchJob(jobId).listen((job) async {
        if (!mounted || job == null || handled) return;

        if (job.status == 'error') {
          handled = true;
          await _jobSub?.cancel();
          if (mounted) {
            setState(() {
              _dubbingBusy = false;
              _statusLine = '';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ബാക്കെൻഡ് പിശക്: ${job.errorMessage}')),
            );
          }
          return;
        }

        if (job.status == 'ready' &&
            job.audioUrl != null &&
            job.audioUrl!.isNotEmpty &&
            (job.durationSec ?? 0) >= 20) {
          handled = true;
          await _jobSub?.cancel();
          _jobSub = null;

          if (!mounted) return;
          setState(() => _statusLine = 'ഓഡിയോ തയ്യാർ — വീഡിയോ + ഡബ് ആരംഭിക്കുന്നു…');

          final seekAt = job.syncSeconds ?? syncSeconds;
          try {
            await _yt.seekTo(seconds: seekAt, allowSeekAhead: true);
          } catch (e) {
            debugPrint('seekTo: $e');
          }
          await _yt.mute();
          await _yt.playVideo();

          await _audioPlayer?.dispose();
          _audioPlayer = AudioPlayer();
          await _audioPlayer!.setReleaseMode(ReleaseMode.release);
          await _audioPlayer!.play(UrlSource(job.audioUrl!));

          if (mounted) {
            setState(() {
              _dubbingBusy = false;
              _statusLine =
                  'ഡബ്ബിംഗ് പ്ലേ ആകുന്നു. ഒറിജിനൽ: മ്യൂട്ട്. “ഒറിജിനൽ ഓഡിയോ” അമർത്തിയാൽ EN തിരിച്ച് കേൾക്കാം.';
            });
          }
        } else if (job.status == 'ready' && mounted) {
          setState(() => _statusLine =
              'ഓഡിയോ ലിങ്ക് ലഭിച്ചു; നീളം ${job.durationSec?.toStringAsFixed(1) ?? "?"} s — കുറഞ്ഞത് 20 s വേണം. വർക്കർ വീണ്ടും റൺ ചെയ്യുക.');
        } else if (job.status == 'processing' && mounted) {
          setState(() => _statusLine = 'സെർവർ പ്രോസസ്സ് ചെയ്യുന്നു…');
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ഡബ്ബിംഗ്: $e')),
        );
        setState(() {
          _dubbingBusy = false;
          _statusLine = '';
        });
      }
    }
  }

  Widget _langButton(String label, TargetLanguage lang) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: FilledButton.tonal(
        onPressed: _dubbingBusy ? null : () => _runLiveDub(lang),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width - 32;
    final playerH = (maxW * 9 / 16).clamp(120.0, 220.0);
    final playerW = playerH * 16 / 9;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'അൽ ജസീറ ഇംഗ്ലീഷ് — ഫയർബേസ് + GitHub ഡബ്ബിംഗ്',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'ഭാഷ തിരഞ്ഞെടുക്കുമ്പോൾ വീഡിയോ നിർത്തും. സ്ക്രീനിലെ സബ്ടൈറ്റ് ടെക്സ്റ്റ് '
            'ഫയർബേസിലേക്ക് അയയ്ക്കും; GitHub Actions വർക്കർ വിവർത്തനം + MP3 ഉണ്ടാക്കി സ്റ്റോറേജിൽ ഇടും. '
            'കുറഞ്ഞത് 20 സെക്കൻഡ് ഓഡിയോ തയ്യാറാകുമ്പോൾ മാത്രം വീഡിയോ (മ്യൂട്ട്) + ഡബ്ബ് ഒരുമിച്ച് തുടങ്ങും.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: playerW.clamp(0, maxW),
                height: playerH,
                child: YoutubePlayer(
                  controller: _yt,
                  aspectRatio: 16 / 9,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ഡബ്ബിംഗ് ഭാഷ',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            children: [
              _langButton('മലയാളം', TargetLanguage.malayalam),
              _langButton('തമിഴ്', TargetLanguage.tamil),
              _langButton('ഉർദു', TargetLanguage.urdu),
              _langButton('ഹിന്ദി', TargetLanguage.hindi),
            ],
          ),
          if (_dubbingBusy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_statusLine.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_statusLine, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _dubbingBusy ? null : _restoreOriginalStream,
            icon: const Icon(Icons.volume_up),
            label: const Text('ഒറിജിനൽ അൽ ജസീറ ഓഡിയോ'),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
