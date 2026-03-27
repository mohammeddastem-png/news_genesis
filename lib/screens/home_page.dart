import 'package:flutter/material.dart';
import '../services/firebase_news_service.dart';
import '../services/admob_service.dart';
import 'live_stream_screen.dart';
import 'dubbing_control_panel.dart';

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

  int _selectedChannelIndex = 0;
  final List<String> channels = ['English', 'Arabic'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize services (these would be injected in production)
    _adMobService = AdMobService();
    _firebaseNewsService = FirebaseNewsService();
    
    _initializeAds();
    _initializeNews();
  }

  void _initializeAds() {
    _adMobService.loadBannerAd();
    _adMobService.loadInterstitialAd();
    _adMobService.loadRewardedAd();
  }

  void _initializeNews() {
    // Load initial news
    _firebaseNewsService.fetchLatestNews(
      channelType: _selectedChannelIndex == 0 ? 'english' : 'arabic',
      limit: 20,
    );
  }

  void _switchChannel(int index) {
    setState(() {
      _selectedChannelIndex = index;
    });

    // Show ad when switching channel
    if (_adMobService.isInterstitialAdReady) {
      _adMobService.showInterstitialAd(
        onAdClosed: () {
          // Load news for new channel
          _firebaseNewsService.fetchLatestNews(
                channelType:
                    _selectedChannelIndex == 0 ? 'english' : 'arabic',
                limit: 20,
              );
        },
      );
    } else {
      // No ad ready, load news directly
      _firebaseNewsService.fetchLatestNews(
            channelType: _selectedChannelIndex == 0 ? 'english' : 'arabic',
            limit: 20,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              // ചാനൽ സെലെക്ഷൻ
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
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ലൈവ് സ്ട്രീം ടാബ്
          const LiveStreamScreen(),
          // ഡബിംഗ് & ഓഡിയോ ടാബ്
          const DubbingControlPanel(),
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
    _adMobService.disposeBannerAd();
    super.dispose();
  }
}
