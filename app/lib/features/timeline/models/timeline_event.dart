import 'package:flutter/foundation.dart';

@immutable
class TimelineEvent {
  final String id;
  final String title;
  final DateTime dateTime;
  final String? description;
  final List<String> emojis;
  final String? spotifyUrl;
  final List<PhotoItem> photos;
  final LocationData? location;
  final String? observations;
  final List<String> tags;
  final bool isCompleted;
  final String? category;
  // null = belongs to the active trip (backward compat with existing Hive data)
  final String? tripId;
  // set when the user marks this event as "vivido"
  final DateTime? experiencedAt;

  const TimelineEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    this.description,
    this.emojis = const [],
    this.spotifyUrl,
    this.photos = const [],
    this.location,
    this.observations,
    this.tags = const [],
    this.isCompleted = false,
    this.category,
    this.tripId,
    this.experiencedAt,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      description: json['description'] as String?,
      emojis: List<String>.from((json['emojis'] as List?) ?? []),
      spotifyUrl: json['spotifyUrl'] as String?,
      photos: ((json['photos'] as List?) ?? [])
          .map((p) => PhotoItem.fromJson(p as Map<String, dynamic>))
          .toList(),
      location: json['location'] != null
          ? LocationData.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      observations: json['observations'] as String?,
      tags: List<String>.from((json['tags'] as List?) ?? []),
      isCompleted: json['isCompleted'] as bool? ?? false,
      category: json['category'] as String?,
      // backward compat: old events without tripId are active-trip events
      tripId: json['tripId'] as String?,
      experiencedAt: json['experiencedAt'] != null
          ? DateTime.parse(json['experiencedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dateTime': dateTime.toIso8601String(),
        'description': description,
        'emojis': emojis,
        'spotifyUrl': spotifyUrl,
        'photos': photos.map((p) => p.toJson()).toList(),
        'location': location?.toJson(),
        'observations': observations,
        'tags': tags,
        'isCompleted': isCompleted,
        'category': category,
        'tripId': tripId,
        'experiencedAt': experiencedAt?.toIso8601String(),
      };

  TimelineEvent copyWith({
    String? id,
    String? title,
    DateTime? dateTime,
    Object? description = _sentinel,
    List<String>? emojis,
    Object? spotifyUrl = _sentinel,
    List<PhotoItem>? photos,
    Object? location = _sentinel,
    Object? observations = _sentinel,
    List<String>? tags,
    bool? isCompleted,
    Object? category = _sentinel,
    Object? tripId = _sentinel,
    Object? experiencedAt = _sentinel,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      description:
          description == _sentinel ? this.description : description as String?,
      emojis: emojis ?? this.emojis,
      spotifyUrl:
          spotifyUrl == _sentinel ? this.spotifyUrl : spotifyUrl as String?,
      photos: photos ?? this.photos,
      location:
          location == _sentinel ? this.location : location as LocationData?,
      observations: observations == _sentinel
          ? this.observations
          : observations as String?,
      tags: tags ?? this.tags,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category == _sentinel ? this.category : category as String?,
      tripId: tripId == _sentinel ? this.tripId : tripId as String?,
      experiencedAt: experiencedAt == _sentinel
          ? this.experiencedAt
          : experiencedAt as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineEvent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const Object _sentinel = Object();

@immutable
class PhotoItem {
  final String url;
  final String? emojiOverlay;
  final String? caption;

  const PhotoItem({
    required this.url,
    this.emojiOverlay,
    this.caption,
  });

  factory PhotoItem.fromJson(Map<String, dynamic> json) => PhotoItem(
        url: json['url'] as String,
        emojiOverlay: json['emojiOverlay'] as String?,
        caption: json['caption'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'emojiOverlay': emojiOverlay,
        'caption': caption,
      };
}

@immutable
class LocationData {
  final String name;
  final double? lat;
  final double? lng;

  const LocationData({
    required this.name,
    this.lat,
    this.lng,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
        name: json['name'] as String,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'lat': lat,
        'lng': lng,
      };
}
