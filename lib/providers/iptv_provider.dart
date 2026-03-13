import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';
import '../services/m3u_parser.dart';

class IPTVProvider extends ChangeNotifier {
  List<Playlist> _playlists = [];
  List<Channel> _favorites = [];
  List<Channel> _recentChannels = [];
  Channel? _currentChannel;
  String? _selectedGroup;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  int _selectedPlaylistIndex = 0;

  // Getters
  List<Playlist> get playlists => _playlists;
  List<Channel> get favorites => _favorites;
  List<Channel> get recentChannels => _recentChannels;
  Channel? get currentChannel => _currentChannel;
  String? get selectedGroup => _selectedGroup;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedPlaylistIndex => _selectedPlaylistIndex;

  Playlist? get currentPlaylist =>
      _playlists.isEmpty ? null : _playlists[_selectedPlaylistIndex];

  List<Channel> get allChannels {
    if (currentPlaylist == null) return [];
    return currentPlaylist!.channels;
  }

  List<String> get groups => currentPlaylist?.groups ?? [];

  List<Channel> get filteredChannels {
    var channels = allChannels;

    if (_selectedGroup != null && _selectedGroup!.isNotEmpty) {
      channels = channels.where((c) => c.group == _selectedGroup).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      channels = channels
          .where((c) =>
              c.name.toLowerCase().contains(query) ||
              (c.group?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    return channels;
  }

  IPTVProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load playlists
    final playlistsJson = prefs.getString('playlists');
    if (playlistsJson != null) {
      final List decoded = json.decode(playlistsJson);
      _playlists = decoded.map((p) => Playlist.fromJson(p)).toList();
    }

    // Load favorites
    final favJson = prefs.getString('favorites');
    if (favJson != null) {
      final List decoded = json.decode(favJson);
      _favorites = decoded.map((c) => Channel.fromJson(c)).toList();
    }

    // Load recent
    final recentJson = prefs.getString('recent');
    if (recentJson != null) {
      final List decoded = json.decode(recentJson);
      _recentChannels = decoded.map((c) => Channel.fromJson(c)).toList();
    }

    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'playlists',
      json.encode(_playlists.map((p) => p.toJson()).toList()),
    );
    await prefs.setString(
      'favorites',
      json.encode(_favorites.map((c) => c.toJson()).toList()),
    );
    await prefs.setString(
      'recent',
      json.encode(_recentChannels.take(20).map((c) => c.toJson()).toList()),
    );
  }

  Future<void> addPlaylist(String name, String url) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final channels = await M3UParser.parseFromUrl(url);
      final playlist = Playlist(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        url: url,
        channels: channels,
        addedAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      _playlists.add(playlist);
      _selectedPlaylistIndex = _playlists.length - 1;
      await _saveData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPlaylist(int index) async {
    if (index >= _playlists.length) return;
    _isLoading = true;
    notifyListeners();

    try {
      final playlist = _playlists[index];
      final channels = await M3UParser.parseFromUrl(playlist.url);
      _playlists[index] = Playlist(
        id: playlist.id,
        name: playlist.name,
        url: playlist.url,
        channels: channels,
        addedAt: playlist.addedAt,
        lastUpdated: DateTime.now(),
      );
      await _saveData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removePlaylist(int index) {
    _playlists.removeAt(index);
    if (_selectedPlaylistIndex >= _playlists.length) {
      _selectedPlaylistIndex = _playlists.isEmpty ? 0 : _playlists.length - 1;
    }
    _saveData();
    notifyListeners();
  }

  void selectPlaylist(int index) {
    _selectedPlaylistIndex = index;
    _selectedGroup = null;
    _searchQuery = '';
    notifyListeners();
  }

  void setCurrentChannel(Channel channel) {
    _currentChannel = channel;
    // Add to recent
    _recentChannels.removeWhere((c) => c.id == channel.id);
    _recentChannels.insert(
        0, channel.copyWith(lastWatched: DateTime.now()));
    if (_recentChannels.length > 20) {
      _recentChannels = _recentChannels.take(20).toList();
    }
    _saveData();
    notifyListeners();
  }

  void toggleFavorite(Channel channel) {
    final index = _favorites.indexWhere((c) => c.id == channel.id);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.add(channel);
    }
    _saveData();
    notifyListeners();
  }

  bool isFavorite(Channel channel) =>
      _favorites.any((c) => c.id == channel.id);

  void setSelectedGroup(String? group) {
    _selectedGroup = group;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Demo channels for testing
  Future<void> loadDemoPlaylist() async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 1));
    
    final demoChannels = [
      Channel(id: 'd1', name: 'Al Jazeera English', url: 'https://live-hls-web-aje.getaj.net/AJE/01.m3u8', logo: 'https://upload.wikimedia.org/wikipedia/en/thumb/f/f2/Aljazeera_eng.svg/240px-Aljazeera_eng.svg.png', group: 'News'),
      Channel(id: 'd2', name: 'France 24 English', url: 'https://static.france24.com/live/F24_EN_LO_HLS/live_web.m3u8', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/France24_logo.svg/240px-France24_logo.svg.png', group: 'News'),
      Channel(id: 'd3', name: 'NASA TV', url: 'https://nasa-i.akamaihd.net/hls/live/253565/NASA-NTV1-HLS/master.m3u8', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/NASA_logo.svg/200px-NASA_logo.svg.png', group: 'Science'),
      Channel(id: 'd4', name: 'Bloomberg TV', url: 'https://bloomberg-hls.akamaized.net/vs/client/hls/live.m3u8', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/NewBloombergLogo.svg/220px-NewBloombergLogo.svg.png', group: 'Business'),
      Channel(id: 'd5', name: 'DW English', url: 'https://dwamdstream102.akamaized.net/hls/live/2015525/dwstream102/index.m3u8', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/75/Deutsche_Welle_symbol_2012.svg/200px-Deutsche_Welle_symbol_2012.svg.png', group: 'News'),
      Channel(id: 'd6', name: 'RT News', url: 'https://rt-glb.rttv.com/live/rtnews/playlist.m3u8', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/RT_logo.svg/220px-RT_logo.svg.png', group: 'News'),
      Channel(id: 'd7', name: 'Eurosport 1', url: 'https://str-cdn.bigstream.ro/eurosport1/eurosport1.m3u8', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/43/Eurosport_1_logo_2015.svg/240px-Eurosport_1_logo_2015.svg.png', group: 'Sports'),
      Channel(id: 'd8', name: 'beIN Sports', url: 'https://wl-bein.cf.cdn.ez.io/hls/live/605965/bein_sport1/index.m3u8', logo: 'https://upload.wikimedia.org/wikipedia/en/thumb/b/be/BeIN_Sports_logo.svg/200px-BeIN_Sports_logo.svg.png', group: 'Sports'),
    ];

    final playlist = Playlist(
      id: 'demo',
      name: '📺 Demo Playlist',
      url: 'demo',
      channels: demoChannels,
      addedAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    _playlists.add(playlist);
    _selectedPlaylistIndex = _playlists.length - 1;
    _isLoading = false;
    await _saveData();
    notifyListeners();
  }
}
