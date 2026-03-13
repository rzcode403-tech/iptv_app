import 'package:http/http.dart' as http;
import '../models/channel.dart';

class M3UParser {
  static Future<List<Channel>> parseFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode == 200) {
        return parseContent(response.body);
      }
      throw Exception('Failed to load playlist: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error loading playlist: $e');
    }
  }

  static List<Channel> parseContent(String content) {
    final channels = <Channel>[];
    final lines = content.split('\n');
    
    if (lines.isEmpty || !lines.first.trim().startsWith('#EXTM3U')) {
      throw Exception('Invalid M3U file format');
    }

    Map<String, String> currentInfo = {};
    int channelIndex = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.startsWith('#EXTINF:')) {
        currentInfo = _parseExtInf(line);
        currentInfo['id'] = 'ch_${channelIndex++}';
      } else if (line.isNotEmpty && !line.startsWith('#') && currentInfo.isNotEmpty) {
        currentInfo['url'] = line;
        channels.add(Channel.fromM3U(currentInfo));
        currentInfo = {};
      }
    }

    return channels;
  }

  static Map<String, String> _parseExtInf(String line) {
    final info = <String, String>{};
    
    // Extract attributes
    final attrRegex = RegExp(r'(\w[\w-]*)="([^"]*)"');
    for (final match in attrRegex.allMatches(line)) {
      info[match.group(1)!] = match.group(2)!;
    }
    
    // Extract channel name (last part after comma)
    final commaIndex = line.lastIndexOf(',');
    if (commaIndex != -1) {
      info['name'] = line.substring(commaIndex + 1).trim();
    }
    
    return info;
  }
}
