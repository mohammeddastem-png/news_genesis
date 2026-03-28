import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/ai_dubbing_service.dart';
import '../services/advanced_audio_service.dart';

class DubbingControlPanel extends StatefulWidget {
  const DubbingControlPanel({super.key});

  @override
  State<DubbingControlPanel> createState() => _DubbingControlPanelState();
}

class _DubbingControlPanelState extends State<DubbingControlPanel> {
  AIDubbingService? _dubbingService;
  late AdvancedAudioService _audioService;

  TargetLanguage _selectedLanguage = TargetLanguage.malayalam;
  bool _isTranslating = false;
  bool _isPlaying = false;
  String _translatedText = '';
  List<String> _detectedSpeakers = [];
  String _selectedSpeaker = 'All';
  Duration _audioSyncOffset = const Duration(seconds: 7);

  @override
  void initState() {
    super.initState();
    if (AppConfig.hasGeminiApiKey) {
      _dubbingService = AIDubbingService(apiKey: AppConfig.geminiApiKey);
    }
    _audioService = AdvancedAudioService();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      await _audioService.initAudioSession();
      debugPrint('Audio session initialized');
    } catch (e) {
      debugPrint('Warning: Could not initialize audio session: $e');
    }
  }

  Future<void> _translateAndDub(String sourceText) async {
    if (!AppConfig.hasGeminiApiKey || _dubbingService == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add your API key: flutter run --dart-define=GEMINI_API_KEY=your_key',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isTranslating = true;
      _translatedText = '';
    });

    try {
      final translated = await _dubbingService!.translateNewsContent(
        sourceText,
        'en', // Source language (Al Jazeera English)
        _selectedLanguage,
      );

      setState(() {
        _translatedText = translated;
        _isTranslating = false;
      });

      // ഓഡിയോ ഡബിംഗ് പ്ലേ ചെയ്യുക
      await _playDubbing(translated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTranslating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Translation error: $e')),
      );
    }
  }

  Future<void> _playDubbing(String translatedText) async {
    try {
      setState(() {
        _isPlaying = true;
      });

      await _dubbingService!.playDubbing(
        translatedText,
        _selectedLanguage,
        _audioSyncOffset,
      );

      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      debugPrint('Error playing dubbing: $e');
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _detectSpeakers() async {
    try {
      // Placeholder implementation
      setState(() {
        _detectedSpeakers = ['Speaker 1', 'Speaker 2', 'Speaker 3'];
        _selectedSpeaker = 'All';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speakers detected: 3')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error detecting speakers: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!AppConfig.hasGeminiApiKey)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Material(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.key_off, color: Colors.orange.shade900),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Gemini is disabled until you pass GEMINI_API_KEY at '
                            'build time. Example: '
                            'flutter run --dart-define=GEMINI_API_KEY=your_key',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // ഭാഷ സെലെക്ഷൻ
            Text(
              'Dubbing Language',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<TargetLanguage>(
                value: _selectedLanguage,
                isExpanded: true,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(
                    value: TargetLanguage.malayalam,
                    child: Row(
                      children: const [
                        Icon(Icons.language),
                        SizedBox(width: 8),
                        Text('Malayalam (മലയാളം)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: TargetLanguage.tamil,
                    child: Row(
                      children: const [
                        Icon(Icons.language),
                        SizedBox(width: 8),
                        Text('Tamil (தமிழ்)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: TargetLanguage.urdu,
                    child: Row(
                      children: const [
                        Icon(Icons.language),
                        SizedBox(width: 8),
                        Text('Urdu (اردو)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: TargetLanguage.hindi,
                    child: Row(
                      children: const [
                        Icon(Icons.language),
                        SizedBox(width: 8),
                        Text('Hindi (हिन्दी)'),
                      ],
                    ),
                  ),
                ],
                onChanged: (TargetLanguage? newLanguage) {
                  setState(() {
                    _selectedLanguage = newLanguage ?? TargetLanguage.malayalam;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // സ്പീക്കർ നിർണയനം
            Text(
              'Speaker Diarization',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text('Detect Speakers'),
              onPressed: _detectedSpeakers.isEmpty ? _detectSpeakers : null,
            ),
            const SizedBox(height: 12),
            if (_detectedSpeakers.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  value: _selectedSpeaker,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem(
                      value: 'All',
                      child: Text('All Speakers'),
                    ),
                    ..._detectedSpeakers.map((speaker) {
                      return DropdownMenuItem(
                        value: speaker,
                        child: Text(speaker),
                      );
                    }),
                  ],
                  onChanged: (String? newSpeaker) {
                    setState(() {
                      _selectedSpeaker = newSpeaker ?? 'All';
                    });
                  },
                ),
              ),
            const SizedBox(height: 24),

            // ഓഡിയോ സിങ്ക് ഓഫ്സെറ്റ്
            Text(
              'Audio Sync Offset (milliseconds)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _audioSyncOffset.inMilliseconds.toDouble(),
                    min: 0,
                    max: 10000, // 0-10 സെക്കൻഡ്
                    divisions: 100,
                    label:
                        '${(_audioSyncOffset.inMilliseconds / 1000).toStringAsFixed(1)}s',
                    onChanged: (value) {
                      setState(() {
                        _audioSyncOffset =
                            Duration(milliseconds: value.toInt());
                      });
                    },
                  ),
                ),
                Text(
                  '${(_audioSyncOffset.inMilliseconds / 1000).toStringAsFixed(1)}s',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // നിരൂപണ ബോക്സ്
            Text(
              'News Content (Sample)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _translatedText.isEmpty
                    ? 'Translate news content to see it here...'
                    : _translatedText,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 24),

            // ട്രാൻസ്ലേറ്റ് ബട്ടൺ
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: _isTranslating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.translate),
                label: Text(
                  _isTranslating ? 'Translating...' : 'Translate & Dub',
                  style: const TextStyle(fontSize: 16),
                ),
                onPressed: (_isTranslating || !AppConfig.hasGeminiApiKey)
                    ? null
                    : () {
                        // സാമ്പൾ ന്യൂസ് ടെക്സ്റ്റ് (Firebase യിൽ നിന്ന് ലോഡ് ചെയ്യാൻ പ്രയോഗിക്കേണ്ടതുണ്ട്)
                        const sampleText =
                            'Al Jazeera brings you the latest news from the Middle East. Breaking news about regional developments and international affairs continues to dominate headlines.';
                        _translateAndDub(sampleText);
                      },
              ),
            ),
            const SizedBox(height: 16),

            // ഓഡിയോ കൺട്രോൾ
            if (_translatedText.isNotEmpty)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      label: Text(
                        _isPlaying ? 'Stop Audio' : 'Play Audio',
                        style: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        if (_isPlaying) {
                          // ഓഡിയോ സ്റ്റോപ്പ് ചെയ്യുക
                          setState(() {
                            _isPlaying = false;
                          });
                        } else {
                          _playDubbing(_translatedText);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ഓഡിയോ കിഴ് ജാനകാരി
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Audio Information',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Language:',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              _selectedLanguage.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sync Offset:',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${(_audioSyncOffset.inMilliseconds / 1000).toStringAsFixed(1)}s',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Speaker:',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              _selectedSpeaker,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dubbingService?.dispose();
    _audioService.dispose();
    super.dispose();
  }
}
