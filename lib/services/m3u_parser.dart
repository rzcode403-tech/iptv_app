import 'package:http/http.dart' as http;
import '../models/channel.dart';

class M3UParser {
  static Future<List<Channel>> parseFromUrl(String url) async {
    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 30),
    );
    if (response.statusCode == 200) {
      return parseContent(response.body);
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  static List<Channel> parseContent(String content) {
    final channels = <Channel>[];
    final lines = content.split('\n');

    if (lines.isEmpty || !lines.first.trim().startsWith('#EXTM3U')) {
      throw Exception('Invalid M3U format');
    }

    Map<String, String> currentInfo = {};
    int index = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('#EXTINF:')) {
        currentInfo = _parseExtInf(trimmed);
        currentInfo['id'] = 'ch_${index++}';
      } else if (trimmed.isNotEmpty && !trimmed.startsWith('#') && currentInfo.isNotEmpty) {
        currentInfo['url'] = trimmed;
        channels.add(Channel.fromM3U(currentInfo));
        currentInfo = {};
      }
    }
    return channels;
  }

  static Map<String, String> _parseExtInf(String line) {
    final info = <String, String>{};
    final attrRegex = RegExp(r'([\w-]+)="([^"]*)"');
    for (final match in attrRegex.allMatches(line)) {
      info[match.group(1)!] = match.group(2)!;
    }
    final commaIndex = line.lastIndexOf(',');
    if (commaIndex != -1) {
      info['name'] = line.substring(commaIndex + 1).trim();
    }
    return info;
  }
}
