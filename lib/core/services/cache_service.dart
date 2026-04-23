import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _boxName = 'grh_mobile_cache';

  Future<Box<String>> _box() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<String>(_boxName);
    }
    return Hive.openBox<String>(_boxName);
  }

  Future<Map<String, dynamic>?> readMap(String key) async {
    final raw = (await _box()).get(key);
    if (raw == null) {
      return null;
    }
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<List<Map<String, dynamic>>> readList(String key) async {
    final raw = (await _box()).get(key);
    if (raw == null) {
      return <Map<String, dynamic>>[];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<void> writeMap(String key, Map<String, dynamic> value) async {
    await (await _box()).put(key, jsonEncode(value));
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> value) async {
    await (await _box()).put(key, jsonEncode(value));
  }
}
