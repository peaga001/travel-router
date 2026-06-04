import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/timeline_event.dart';
import '../repositories/timeline_repository.dart';

final timelineRepositoryProvider =
    Provider<TimelineRepository>((ref) => TimelineRepository());

/// Active-trip events only (tripId == null in storage).
final timelineProvider =
    AsyncNotifierProvider<TimelineNotifier, List<TimelineEvent>>(
  TimelineNotifier.new,
);

class TimelineNotifier extends AsyncNotifier<List<TimelineEvent>> {
  TimelineRepository get _repo => ref.read(timelineRepositoryProvider);

  @override
  Future<List<TimelineEvent>> build() => _repo.getActiveEvents();

  Future<void> add(TimelineEvent event) async {
    await _repo.save(event);
    ref.invalidateSelf();
    await future;
  }

  Future<void> saveEvent(TimelineEvent event) async {
    await _repo.save(event);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> toggleCompleted(String id) async {
    final events = await future;
    final event = events.firstWhere((e) => e.id == id);
    final nowCompleted = !event.isCompleted;
    await saveEvent(event.copyWith(
      isCompleted: nowCompleted,
      experiencedAt: nowCompleted ? DateTime.now() : null,
    ));
  }
}

/// Single active event by id.
final timelineEventProvider =
    FutureProvider.family<TimelineEvent?, String>((ref, id) async {
  final events = await ref.watch(timelineProvider.future);
  try {
    return events.firstWhere((e) => e.id == id);
  } catch (_) {
    return null;
  }
});

/// Events for a specific completed trip (used in CompletedTripDetailScreen).
final completedTripEventsProvider =
    FutureProvider.family<List<TimelineEvent>, String>((ref, tripId) {
  return ref.read(timelineRepositoryProvider).getEventsByTripId(tripId);
});
