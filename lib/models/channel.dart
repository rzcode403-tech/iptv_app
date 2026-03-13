class Channel {
  final String id;
  final String name;
  final String url;
  final String? logo;
  final String? group;
  final String? epgId;
  bool isFavorite;
  DateTime? lastWatched;

  Channel({
    required this.id,
    required this.name,
    required this.url,
    this.logo,
    this.group,
    this.epgId,
    this.isFavorite = false,
    this.lastWatched,
  });

  factory Channel.fromM3U(Map<String, dynamic> data) {
    return Channel(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: data['name'] ?? 'Unknown Channel',
      url: data['url'] ?? '',
      logo: data['tvg-logo'] ?? data['logo'],
      group: data['group-title'] ?? data['group'],
      epgId: data['tvg-id'],
    );
  }

  Channel copyWith({
    String? id,
    String? name,
    String? url,
    String? logo,
    String? group,
    String? epgId,
    bool? isFavorite,
    DateTime? lastWatched,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      logo: logo ?? this.logo,
      group: group ?? this.group,
      epgId: epgId ?? this.epgId,
      isFavorite: isFavorite ?? this.isFavorite,
      lastWatched: lastWatched ?? this.lastWatched,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'logo': logo,
    'group': group,
    'epgId': epgId,
    'isFavorite': isFavorite,
    'lastWatched': lastWatched?.toIso8601String(),
  };

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
    id: json['id'],
    name: json['name'],
    url: json['url'],
    logo: json['logo'],
    group: json['group'],
    epgId: json['epgId'],
    isFavorite: json['isFavorite'] ?? false,
    lastWatched: json['lastWatched'] != null
        ? DateTime.parse(json['lastWatched'])
        : null,
  );
}

class Playlist {
  final String id;
  final String name;
  final String url;
  final List<Channel> channels;
  final DateTime addedAt;
  DateTime? lastUpdated;

  Playlist({
    required this.id,
    required this.name,
    required this.url,
    this.channels = const [],
    required this.addedAt,
    this.lastUpdated,
  });

  List<String> get groups {
    final groups = channels
        .where((c) => c.group != null && c.group!.isNotEmpty)
        .map((c) => c.group!)
        .toSet()
        .toList();
    groups.sort();
    return groups;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'channels': channels.map((c) => c.toJson()).toList(),
    'addedAt': addedAt.toIso8601String(),
    'lastUpdated': lastUpdated?.toIso8601String(),
  };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
    id: json['id'],
    name: json['name'],
    url: json['url'],
    channels: (json['channels'] as List? ?? [])
        .map((c) => Channel.fromJson(c))
        .toList(),
    addedAt: DateTime.parse(json['addedAt']),
    lastUpdated: json['lastUpdated'] != null
        ? DateTime.parse(json['lastUpdated'])
        : null,
  );
}
