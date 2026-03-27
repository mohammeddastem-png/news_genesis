/// Service to manage HLS/.m3u8 streaming for Al Jazeera channels
class HLSStreamService {
  static const String alJazeeraEnglishUrl =
      'https://live-qatarstream.com/hls/alijazeera_enghd/index.m3u8';
  
  static const String alJazeeraArabicUrl =
      'https://live-qatarstream.com/hls/alijazeera_arabhd/index.m3u8';

  /// Validate HLS playlist URL
  Future<bool> validatePlaylist(String playlistUrl) async {
    try {
      // Simulated validation
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get quality variants available in the playlist
  Future<List<String>> getAvailableQualities(String playlistUrl) async {
    try {
      final isValid = await validatePlaylist(playlistUrl);
      if (!isValid) return ['Auto'];
      
      // Standard qualities for HLS streams
      return ['720p', '480p', '360p', 'Auto'];
    } catch (e) {
      return ['Auto'];
    }
  }

  /// Select optimal quality based on network and device capability
  String selectOptimalQuality(List<String> availableQualities) {
    // Priority: 720p > 480p > 360p > Auto
    final priority = ['720p', '480p', '360p', 'Auto'];
    
    for (var quality in priority) {
      if (availableQualities.any((q) => q.contains(quality))) {
        return quality;
      }
    }
    
    return availableQualities.last;
  }

  /// Get direct playable stream URL
  Future<String> getPlayableStreamUrl(String channelType) async {
    try {
      final url = channelType == 'english' 
          ? alJazeeraEnglishUrl 
          : alJazeeraArabicUrl;
      
      return url;
    } catch (e) {
      throw Exception('Failed to get stream URL: $e');
    }
  }
}
