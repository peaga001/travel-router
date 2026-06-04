import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../models/trip.dart';

class TripRepository {
  Future<List<Trip>> getCompleted() async {
    final box = await Hive.openBox<String>(AppConstants.tripsBox);
    return box.keys
        .map((k) => Trip.fromJson(
            jsonDecode(box.get(k as String)!) as Map<String, dynamic>))
        .where((t) => t.status == TripStatus.completed)
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
  }

  Future<void> save(Trip trip) async {
    final box = await Hive.openBox<String>(AppConstants.tripsBox);
    await box.put(trip.id, jsonEncode(trip.toJson()));
  }
}
