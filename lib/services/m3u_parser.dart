import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';

class M3UParser {
  // تحميل من رابط مع دعم كامل لـ UTF-8 والعربية
  static Future<List<Channel>> parseFromUrl(String url) async {
    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 30),
    );
    if (response.statusCode == 200) {
      // فك ترميز UTF-8 بشكل صحيح لدعم العربية والفرنسية
      final content = utf8.decode(response.bodyBytes, allowMalformed: true);
      return parseContent(content);
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  // تحميل من ملف محلي
  static Future<List<Channel>> parseFromFile(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      try {
        content = latin1.decode(bytes);
      } catch (_) {
        content = String.fromCharCodes(bytes);
      }
    }
    return parseContent(content);
  }

  static List<Channel> parseContent(String content) {
    final channels = <Channel>[];

    // إزالة \r لدعم Windows line endings
    final cleaned = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = cleaned.split('\n');

    if (lines.isEmpty) throw Exception('Empty file');
    if (!lines.first.trim().toUpperCase().startsWith('#EXTM3U')) {
      throw Exception('Invalid M3U format');
    }

    Map<String, String> currentInfo = {};
    int index = 0;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.toUpperCase().startsWith('#EXTINF:')) {
        currentInfo = _parseExtInf(trimmed);
        currentInfo['id'] = 'ch_$index';
        index++;
      } else if (trimmed.isNotEmpty &&
          !trimmed.startsWith('#') &&
          currentInfo.isNotEmpty) {
        currentInfo['url'] = trimmed;
        final ch = Channel.fromM3U(currentInfo);
        if (ch.url.isNotEmpty && ch.name.isNotEmpty) {
          channels.add(ch);
        }
        currentInfo = {};
      }
    }

    debugPrint('✅ Parsed ${channels.length} channels');
    return channels;
  }

  static Map<String, String> _parseExtInf(String line) {
    final info = <String, String>{};

    // استخراج كل الخصائص key="value" مع دعم المسافات
    final attrRegex = RegExp(r'([\w-]+)\s*=\s*"([^"]*)"');
    for (final match in attrRegex.allMatches(line)) {
      final key = match.group(1)!.toLowerCase().trim();
      final value = match.group(2)!.trim();
      info[key] = value;
    }

    // استخراج اسم القناة بعد آخر فاصلة
    final commaIndex = line.lastIndexOf(',');
    if (commaIndex != -1 && commaIndex < line.length - 1) {
      final name = line.substring(commaIndex + 1).trim();
      if (name.isNotEmpty) {
        info['name'] = name;
      }
    }

    // إذا لم يوجد group-title نضع Uncategorized
    final group = info['group-title'];
    if (group == null || group.isEmpty) {
      info['group-title'] = 'Uncategorized';
    }

    return info;
  }
}
