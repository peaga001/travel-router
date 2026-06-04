import 'package:flutter/foundation.dart';

enum TripStatus { active, completed }

@immutable
class Trip {
  final String id;
  final String name;
  final TripStatus status;
  final DateTime createdAt;
  final DateTime firstEventDate;
  final DateTime lastEventDate;
  final DateTime? completedAt;
  final String? finalMessage;
  final int eventCount;
  final List<String> previewEmojis;

  const Trip({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.firstEventDate,
    required this.lastEventDate,
    required this.eventCount,
    this.completedAt,
    this.finalMessage,
    this.previewEmojis = const [],
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      name: json['name'] as String,
      status: TripStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String),
        orElse: () => TripStatus.completed,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      firstEventDate: DateTime.parse(json['firstEventDate'] as String),
      lastEventDate: DateTime.parse(json['lastEventDate'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      finalMessage: json['finalMessage'] as String?,
      eventCount: json['eventCount'] as int? ?? 0,
      previewEmojis:
          List<String>.from((json['previewEmojis'] as List?) ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'firstEventDate': firstEventDate.toIso8601String(),
        'lastEventDate': lastEventDate.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'finalMessage': finalMessage,
        'eventCount': eventCount,
        'previewEmojis': previewEmojis,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trip && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
