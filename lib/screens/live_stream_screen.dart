import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/hls_stream_service.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  final HLSStreamService _hlsService = HLSStreamService();

  VideoPlayerController? _controller;
  bool _isLoading = false;
  bool _isPlaying = false;
  String _selectedQuality = 'Auto';
  List<String> _availableQualities = ['Auto', '720p', '480p', '360p'];
  String _currentChannel = 'english';
  String? _currentStreamUrl;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  Future<void> _initializeStream() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final streamUrl =
          await _hlsService.getPlayableStreamUrl(_currentChannel);
      final qualities = await _hlsService.getAvailableQualities(streamUrl);

      await _controller?.dispose();
      final controller = VideoPlayerController.networkUrl(Uri.parse(streamUrl));
      await controller.initialize();
      await controller.play();

      setState(() {
        _isLoading = false;
        _availableQualities = qualities;
        _currentStreamUrl = streamUrl;
        _controller = controller;
        _isPlaying = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error initializing stream: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stream: $e')),
      );
    }
  }

  void _switchQuality(String quality) {
    setState(() {
      _selectedQuality = quality;
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    final c = _controller;
    if (c == null) return;
    if (_isPlaying) {
      c.play();
    } else {
      c.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Live stream video area
          Container(
            color: Colors.black,
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_controller != null &&
                                _controller!.value.isInitialized)
                              VideoPlayer(_controller!)
                            else
                              Container(
                                color: Colors.black,
                                alignment: Alignment.center,
                                child: Text(
                                  _currentStreamUrl == null
                                      ? 'Loading stream...'
                                      : 'Stream not ready',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            // Play/Pause button overlay
                            if (!_isPlaying)
                              GestureDetector(
                                onTap: _togglePlayPause,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Controls
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Channel toggle
                            DropdownButton<String>(
                              value: _currentChannel,
                              items: const [
                                DropdownMenuItem(
                                  value: 'english',
                                  child: Text('Al Jazeera EN'),
                                ),
                                DropdownMenuItem(
                                  value: 'arabic',
                                  child: Text('Al Jazeera AR'),
                                ),
                              ],
                              onChanged: (v) async {
                                if (v == null || v == _currentChannel) return;
                                setState(() {
                                  _currentChannel = v;
                                });
                                await _initializeStream();
                              },
                            ),
                            // Quality selector
                            DropdownButton<String>(
                              value: _selectedQuality,
                              items: _availableQualities
                                  .map((q) => DropdownMenuItem(
                                        value: q,
                                        child: Text(q),
                                      ))
                                  .toList(),
                              onChanged: (q) {
                                if (q != null) {
                                  _switchQuality(q);
                                }
                              },
                            ),
                            // Play/Pause button
                            IconButton(
                              onPressed: _togglePlayPause,
                              icon: Icon(
                                _isPlaying ? Icons.pause_circle : Icons.play_circle,
                                color: Colors.amber,
                                size: 36,
                              ),
                            ),
                            // LIVE badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: Colors.white,
                                  ),
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
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
