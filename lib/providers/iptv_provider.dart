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

  List<Channel> get allChannels => currentPlaylist?.channels ?? [];

  List<String> get groups => currentPlaylist?.groups ?? [];

  List<Channel> get filteredChannels {
    var channels = allChannels;
    if (_selectedGroup != null && _selectedGroup!.isNotEmpty) {
      channels = channels.where((c) => c.group == _selectedGroup).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      channels = channels.where((c) =>
        c.name.toLowerCase().contains(q) ||
        (c.group?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    return channels;
  }

  IPTVProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = prefs.getString('playlists');
      if (playlistsJson != null) {
        final List decoded = json.decode(playlistsJson) as List;
        _playlists = decoded
            .map((p) => Playlist.fromJson(p as Map<String, dynamic>))
            .toList();
      }
      final favJson = prefs.getString('favorites');
      if (favJson != null) {
        final List decoded = json.decode(favJson) as List;
        _favorites = decoded
            .map((c) => Channel.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      final recentJson = prefs.getString('recent');
      if (recentJson != null) {
        final List decoded = json.decode(recentJson) as List;
        _recentChannels = decoded
            .map((c) => Channel.fromJson(c as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Load error: $e');
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('playlists',
          json.encode(_playlists.map((p) => p.toJson()).toList()));
      await prefs.setString('favorites',
          json.encode(_favorites.map((c) => c.toJson()).toList()));
      await prefs.setString('recent',
          json.encode(_recentChannels.take(20).map((c) => c.toJson()).toList()));
    } catch (e) {
      debugPrint('Save error: $e');
    }
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
      final p = _playlists[index];
      final channels = await M3UParser.parseFromUrl(p.url);
      _playlists[index] = Playlist(
        id: p.id, name: p.name, url: p.url,
        channels: channels,
        addedAt: p.addedAt,
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
    if (_selectedPlaylistIndex >= _playlists.length && _playlists.isNotEmpty) {
      _selectedPlaylistIndex = _playlists.length - 1;
    } else if (_playlists.isEmpty) {
      _selectedPlaylistIndex = 0;
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
    _recentChannels.removeWhere((c) => c.id == channel.id);
    _recentChannels.insert(0, channel.copyWith(lastWatched: DateTime.now()));
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

  Future<void> loadDemoPlaylist() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    final demoChannels = [
      Channel(id: 'd1', name: 'Al Jazeera English', url: 'https://live-hls-web-aje.getaj.net/AJE/01.m3u8', logo: 'https://upload.wikimedia.org/wikipedia/en/thumb/f/f2/Aljazeera_eng.svg/240px-Aljazeera_eng.svg.png', group: 'News'),
      Channel(id: 'd2', name: 'France 24 English', url: 'https://static.france24.com/live/F24_EN_LO_HLS/live_web.m3u8', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/France24_logo.svg/240px-France24_logo.svg.png', group: 'News'),
      Channel(id: 'd3', name: 'NASA TV', url: 'https://nasa-i.akamaihd.net/hls/live/253565/NASA-NTV1-HLS/master.m3u8', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/NASA_logo.svg/200px-NASA_logo.svg.png', group: 'Science'),
      Channel(id: 'd4', name: 'DW English', url: 'https://dwamdstream102.akamaized.net/hls/live/2015525/dwstream102/index.m3u8', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/75/Deutsche_Welle_symbol_2012.svg/200px-Deutsche_Welle_symbol_2012.svg.png', group: 'News'),
      Channel(id: 'd5', name: 'Euronews', url: 'https://euronews-euronews-arabic-1-eg.samsung.wurl.tv/playlist.m3u8', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/Euronews_logo.svg/220px-Euronews_logo.svg.png', group: 'News'),
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
