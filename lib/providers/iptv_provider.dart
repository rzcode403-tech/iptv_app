import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
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

  IPTVProvider() { _loadData(); }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pj = prefs.getString('playlists');
      if (pj != null) {
        _playlists = (json.decode(pj) as List)
            .map((p) => Playlist.fromJson(p as Map<String, dynamic>))
            .toList();
      }
      final fj = prefs.getString('favorites');
      if (fj != null) {
        _favorites = (json.decode(fj) as List)
            .map((c) => Channel.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      final rj = prefs.getString('recent');
      if (rj != null) {
        _recentChannels = (json.decode(rj) as List)
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

  // إضافة playlist من رابط
  Future<void> addPlaylist(String name, String url) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final channels = await M3UParser.parseFromUrl(url);
      _addPlaylistData(name, url, channels);
    } catch (e) {
      _error = 'فشل تحميل القائمة: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // إضافة playlist من ملف محلي
  Future<void> addPlaylistFromFile() async {
    _error = null;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m3u', 'm3u8', 'txt'],
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final filePath = file.path;

      if (filePath == null) {
        _error = 'لا يمكن الوصول للملف';
        notifyListeners();
        return;
      }

      _isLoading = true;
      notifyListeners();

      final channels = await M3UParser.parseFromFile(filePath);
      final name = file.name.replaceAll(RegExp(r'\.(m3u8?|txt)$'), '');
      _addPlaylistData(name, filePath, channels);
    } catch (e) {
      _error = 'خطأ في قراءة الملف: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _addPlaylistData(String name, String url, List<Channel> channels) {
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
    _saveData();
  }

  Future<void> refreshPlaylist(int index) async {
    if (index >= _playlists.length) return;
    final p = _playlists[index];
    if (p.url.startsWith('/') || p.url == 'demo') return;
    _isLoading = true;
    notifyListeners();
    try {
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
    final i = _favorites.indexWhere((c) => c.id == channel.id);
    if (i >= 0) _favorites.removeAt(i);
    else _favorites.add(channel);
    _saveData();
    notifyListeners();
  }

  bool isFavorite(Channel channel) => _favorites.any((c) => c.id == channel.id);

  void setSelectedGroup(String? group) {
    _selectedGroup = group;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearError() { _error = null; notifyListeners(); }
}
