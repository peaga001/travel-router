import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/trip.dart';
import '../providers/timeline_provider.dart';
import '../repositories/timeline_repository.dart';
import '../repositories/trip_repository.dart';

final tripRepositoryProvider =
    Provider<TripRepository>((ref) => TripRepository());

/// All completed trips, sorted newest-first.
final tripProvider =
    AsyncNotifierProvider<TripNotifier, List<Trip>>(TripNotifier.new);

class TripNotifier extends AsyncNotifier<List<Trip>> {
  TripRepository get _tripRepo => ref.read(tripRepositoryProvider);
  TimelineRepository get _timelineRepo =>
      ref.read(timelineRepositoryProvider);

  @override
  Future<List<Trip>> build() => _tripRepo.getCompleted();

  Future<void> completeActiveTrip({
    required String name,
    String? finalMessage,
  }) async {
    final events = await _timelineRepo.getActiveEvents();
    if (events.isEmpty) return;

    // Collect up to 6 unique emojis as visual preview
    final previewEmojis = events
        .expand((e) => e.emojis)
        .toSet()
        .take(6)
        .toList();

    final dates = events.map((e) => e.dateTime).toList()..sort();

    final tripId = const Uuid().v4();
    final trip = Trip(
      id: tripId,
      name: name.trim().isEmpty ? 'Nossa Viagem' : name.trim(),
      status: TripStatus.completed,
      createdAt: dates.first,
      firstEventDate: dates.first,
      lastEventDate: dates.last,
      completedAt: DateTime.now(),
      finalMessage:
          (finalMessage?.trim().isEmpty ?? true) ? null : finalMessage!.trim(),
      eventCount: events.length,
      previewEmojis: previewEmojis,
    );

    await _tripRepo.save(trip);

    // Assign tripId to every active event (moves them out of the active pool)
    for (final event in events) {
      await _timelineRepo.save(event.copyWith(tripId: tripId));
    }

    // Refresh both providers
    ref.invalidateSelf();
    await future;
    ref.invalidate(timelineProvider);
  }
}

/// Single completed trip by ID.
final completedTripByIdProvider =
    FutureProvider.family<Trip?, String>((ref, tripId) async {
  final trips = await ref.watch(tripProvider.future);
  try {
    return trips.firstWhere((t) => t.id == tripId);
  } catch (_) {
    return null;
  }
});
