import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../models/timeline_event.dart';

class TimelineRepository {
  /// Events belonging to the active (in-progress) trip — tripId == null.
  /// Backward compatible: existing Hive data without tripId is treated as active.
  Future<List<TimelineEvent>> getActiveEvents() async {
    final all = await _getAllRaw(seed: true);
    return all.where((e) => e.tripId == null).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Events belonging to a specific completed trip.
  Future<List<TimelineEvent>> getEventsByTripId(String tripId) async {
    final all = await _getAllRaw(seed: false);
    return all.where((e) => e.tripId == tripId).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<TimelineEvent?> getById(String id) async {
    final box = await Hive.openBox<String>(AppConstants.timelineBox);
    final raw = box.get(id);
    if (raw == null) return null;
    return TimelineEvent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(TimelineEvent event) async {
    final box = await Hive.openBox<String>(AppConstants.timelineBox);
    await box.put(event.id, jsonEncode(event.toJson()));
  }

  Future<void> delete(String id) async {
    final box = await Hive.openBox<String>(AppConstants.timelineBox);
    await box.delete(id);
  }

  Future<List<TimelineEvent>> _getAllRaw({required bool seed}) async {
    final box = await Hive.openBox<String>(AppConstants.timelineBox);
    if (seed) await _seedIfEmpty(box);
    return box.keys
        .where((k) => k != AppConstants.seedFlagKey)
        .map((k) => TimelineEvent.fromJson(
            jsonDecode(box.get(k as String)!) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _seedIfEmpty(Box<String> box) async {
    if (box.get(AppConstants.seedFlagKey) != null) return;

    try {
      final jsonStr =
          await rootBundle.loadString(AppConstants.timelineDataPath);
      final List<dynamic> events = jsonDecode(jsonStr) as List<dynamic>;
      for (final e in events) {
        await box.put(
            (e as Map<String, dynamic>)['id'] as String, jsonEncode(e));
      }
    } catch (_) {
      // Assets not yet available; skip seeding
    }

    await box.put(AppConstants.seedFlagKey, 'true');
  }
}
