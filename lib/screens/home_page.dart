import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../firebase_options.dart';
import '../services/admob_service.dart';
import '../services/ai_dubbing_service.dart';
import '../services/ai_service.dart';
import '../services/firebase_news_service.dart';
import '../services/live_dubbing_job_service.dart';
import '../services/tts_service.dart';
import 'dubbing_control_panel.dart';
import 'live_stream_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AdMobService _adMobService;
  late FirebaseNewsService _firebaseNewsService;
  late TtsService _ttsService;
  AIService? _aiService;
  AIDubbingService? _dubbingService;
  LiveDubbingJobService? _liveDubbingJobs;
  bool _servicesInitialized = false;
  String? _initializationError;

  int _selectedChannelIndex = 0;
  bool _isTranslatingNews = false;
  final Map<String, TranslatedHeadline> _translatedByArticleId = {};
  final List<String> channels = ['English', 'Arabic'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    try {
      if (Firebase.apps.isNotEmpty) {
        _liveDubbingJobs = LiveDubbingJobService(
          FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL: DefaultFirebaseOptions.databaseUrl,
          ),
        );
      }
    } catch (e) {
      debugPrint('ലൈവ് ഡബ്ബിംഗ് RTDB: $e');
    }
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize all services
      _adMobService = AdMobService();
      _firebaseNewsService = FirebaseNewsService();
      _ttsService = TtsService();

      if (AppConfig.hasGeminiApiKey) {
        _aiService = AIService(apiKey: AppConfig.geminiApiKey);
        _dubbingService = AIDubbingService(apiKey: AppConfig.geminiApiKey);
      }

      // Skip ads initialization on web
      if (!kIsWeb) {
        try {
          _initializeAds();
        } catch (e) {
          print('Warning: Ad initialization failed: $e');
        }
      }
      
      // Load initial news
      await _initializeNews();
      
      if (mounted) {
        setState(() {
          _servicesInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing services: $e');
      if (mounted) {
        setState(() {
          _servicesInitialized = true;
          _initializationError = e.toString();
        });
      }
    }
  }

  void _initializeAds() {
    try {
      _adMobService.loadBannerAd();
      _adMobService.loadInterstitialAd();
      _adMobService.loadRewardedAd();
    } catch (e) {
      print('Error initializing ads: $e');
    }
  }

  Future<void> _initializeNews() async {
    // Load initial news
    await _firebaseNewsService.fetchLatestNews(
      channelType: _selectedChannelIndex == 0 ? 'english' : 'arabic',
      limit: 20,
    );
    await _translateLoadedNews();
    if (mounted) setState(() {});
  }

  Future<void> _translateLoadedNews() async {
    final ai = _aiService;
    if (ai == null) return;

    setState(() {
      _isTranslatingNews = true;
      _translatedByArticleId.clear();
    });

    final translations =
        await ai.translateArticles(_firebaseNewsService.newsArticles);

    if (!mounted) return;
    setState(() {
      _translatedByArticleId.addAll(translations);
      _isTranslatingNews = false;
    });
  }

  Future<void> _switchChannel(int index) async {
    setState(() {
      _selectedChannelIndex = index;
    });

    Future<void> loadNewsForChannel() async {
      await _firebaseNewsService.fetchLatestNews(
        channelType: _selectedChannelIndex == 0 ? 'english' : 'arabic',
        limit: 20,
      );
      await _translateLoadedNews();
      if (!mounted) return;
      setState(() {});
    }

    // Show ad when switching channel
    if (_adMobService.isInterstitialAdReady) {
      _adMobService.showInterstitialAd(
        onAdClosed: () async {
          await loadNewsForChannel();
        },
      );
    } else {
      // No ad ready, load news directly
      await loadNewsForChannel();
    }
  }

  Widget _buildNewsTab() {
    final articles = _firebaseNewsService.newsArticles;
    if (articles.isEmpty) {
      return const Center(child: Text('No news available'));
    }

    return RefreshIndicator(
      onRefresh: _initializeNews,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          final translated = _translatedByArticleId[article.id];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    translated?.malayalam.isNotEmpty == true
                        ? 'Malayalam: ${translated!.malayalam}'
                        : 'Malayalam: (translation pending)',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    translated?.hindi.isNotEmpty == true
                        ? 'Hindi: ${translated!.hindi}'
                        : 'Hindi: (translation pending)',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: translated == null ||
                                translated.malayalam.isEmpty
                            ? null
                            : () => _ttsService.speak(
                                  text: translated.malayalam,
                                  languageCode: 'ml-IN',
                                ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play Malayalam'),
                      ),
                      OutlinedButton.icon(
                        onPressed:
                            translated == null || translated.hindi.isEmpty
                                ? null
                                : () => _ttsService.speak(
                                      text: translated.hindi,
                                      languageCode: 'hi-IN',
                                    ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play Hindi'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
    if (!_servicesInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('News Genesis'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing News Genesis...'),
            ],
          ),
        ),
      );
    }

    // Show error if initialization failed
    if (_initializationError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('News Genesis'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to initialize app'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _initializationError ?? 'Unknown error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _servicesInitialized = false;
                    _initializationError = null;
                  });
                  _initializeServices();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'News Genesis',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Live'),
            Tab(text: 'Dubbing'),
            Tab(text: 'News'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings screen നേക്ക് നാവിഗേറ്റ് ചെയ്യുക
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon')),
              );
            },
          ),
          if (_isTranslatingNews)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: channels.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    onPressed: () => _switchChannel(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedChannelIndex == index
                          ? Colors.black
                          : Colors.grey[300],
                      foregroundColor: _selectedChannelIndex == index
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          index == 0
                              ? Icons.language
                              : Icons.language_outlined,
                        ),
                        const SizedBox(width: 8),
                        Text(channels[index]),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (!AppConfig.hasGeminiApiKey)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                'Translations need a Gemini API key. Run with '
                '--dart-define=GEMINI_API_KEY=your_key (see lib/config/app_config.dart).',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                LiveStreamScreen(
                  dubbingJobService: _liveDubbingJobs,
                  dubbingService: _dubbingService,
                ),
                const DubbingControlPanel(),
                _buildNewsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(8),
        child: _adMobService.getBannerAdWidget(),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ttsService.stop();
    _dubbingService?.dispose();
    _adMobService.disposeBannerAd();
    super.dispose();
  }
}
