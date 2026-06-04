import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../models/checklist_item.dart';

class ChecklistRepository {
  Future<List<ChecklistItem>> getAll() async {
    final box = await Hive.openBox<String>(AppConstants.checklistBox);
    await _seedIfEmpty(box);

    return box.keys
        .where((k) => k != AppConstants.seedFlagKey)
        .map((k) => ChecklistItem.fromJson(
            jsonDecode(box.get(k as String)!) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<void> save(ChecklistItem item) async {
    final box = await Hive.openBox<String>(AppConstants.checklistBox);
    await box.put(item.id, jsonEncode(item.toJson()));
  }

  Future<void> delete(String id) async {
    final box = await Hive.openBox<String>(AppConstants.checklistBox);
    await box.delete(id);
  }

  Future<void> reorder(List<ChecklistItem> items) async {
    final box = await Hive.openBox<String>(AppConstants.checklistBox);
    final batch = box.toMap();
    for (var i = 0; i < items.length; i++) {
      final updated = items[i].copyWith(order: i);
      batch[updated.id] = jsonEncode(updated.toJson());
    }
    await box.putAll(batch);
  }

  Future<void> _seedIfEmpty(Box<String> box) async {
    if (box.get(AppConstants.seedFlagKey) != null) return;

    try {
      final jsonStr =
          await rootBundle.loadString(AppConstants.checklistDataPath);
      final List<dynamic> items = jsonDecode(jsonStr) as List<dynamic>;
      for (final item in items) {
        final map = item as Map<String, dynamic>;
        await box.put(map['id'] as String, jsonEncode(map));
      }
    } catch (_) {
      // Assets not yet available; skip seeding
    }

    await box.put(AppConstants.seedFlagKey, 'true');
  }
}
