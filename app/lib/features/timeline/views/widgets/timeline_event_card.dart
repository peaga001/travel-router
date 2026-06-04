import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/timeline_event.dart';

class TimelineEventCard extends StatelessWidget {
  final TimelineEvent event;
  final bool isFirst;
  final bool isLast;
  final bool readOnly;

  const TimelineEventCard({
    super.key,
    required this.event,
    required this.isFirst,
    required this.isLast,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TimelineConnector(
            isFirst: isFirst,
            isLast: isLast,
            isCompleted: event.isCompleted,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 16,
                bottom: 20,
              ),
              child: _EventCard(event: event, readOnly: readOnly),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isCompleted;

  const _TimelineConnector({
    required this.isFirst,
    required this.isLast,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Column(
        children: [
          if (!isFirst)
            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  width: 2,
                  color: AppColors.timelineLine,
                ),
              ),
            )
          else
            const SizedBox(height: 20),

          // Dot
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.success : AppColors.timelineDot,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 9, color: Colors.white)
                : null,
          ),

          if (!isLast)
            Expanded(
              flex: 5,
              child: Center(
                child: Container(
                  width: 2,
                  color: AppColors.timelineLine,
                ),
              ),
            )
          else
            const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final TimelineEvent event;
  final bool readOnly;

  const _EventCard({required this.event, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final dateStr = DateFormat('dd MMM · HH:mm', 'pt_BR').format(event.dateTime);

    return GestureDetector(
      onTap: readOnly ? null : () => context.go('/timeline/detail/${event.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(color: AppColors.outline),
          boxShadow: [
            BoxShadow(
              color: AppColors.onBackground.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photos row
            if (event.photos.isNotEmpty) _PhotosPreview(photos: event.photos),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emojis
                  if (event.emojis.isNotEmpty) ...[
                    Text(
                      event.emojis.join('  '),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Title
                  Text(
                    event.title,
                    style: tt.titleMedium?.copyWith(
                      color: event.isCompleted
                          ? AppColors.muted
                          : AppColors.onBackground,
                      decoration: event.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Date
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(dateStr, style: tt.bodySmall),
                      if (event.location != null) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            event.location!.name,
                            style: tt.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Description snippet
                  if (event.description != null &&
                      event.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.description!,
                      style: tt.bodySmall?.copyWith(
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Tags row
                  if (event.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: event.tags
                          .map((tag) => _TagChip(tag: tag))
                          .toList(),
                    ),
                  ],

                  // Spotify pill
                  if (event.spotifyUrl != null) ...[
                    const SizedBox(height: 10),
                    _SpotifyPill(url: event.spotifyUrl!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotosPreview extends StatelessWidget {
  final List<PhotoItem> photos;

  const _PhotosPreview({required this.photos});

  @override
  Widget build(BuildContext context) {
    if (photos.length == 1) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLg),
        ),
        child: _buildPhoto(photos.first, height: 160, width: double.infinity),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppConstants.radiusLg),
      ),
      child: SizedBox(
        height: 120,
        child: Row(
          children: [
            Expanded(child: _buildPhoto(photos.first)),
            const SizedBox(width: 2),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildPhoto(photos[1]),
                  if (photos.length > 2)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Text(
                          '+${photos.length - 2}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(PhotoItem photo,
      {double? height, double? width}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        photo.url.startsWith('assets/')
            ? Image.asset(
                photo.url,
                fit: BoxFit.cover,
                height: height,
                width: width,
                errorBuilder: (_, __, ___) => const _PhotoPlaceholder(),
              )
            : const _PhotoPlaceholder(),
        if (photo.emojiOverlay != null)
          Positioned(
            bottom: 8,
            right: 8,
            child: Text(
              photo.emojiOverlay!,
              style: const TextStyle(fontSize: 22),
            ),
          ),
      ],
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.image_rounded,
          color: AppColors.primaryLight,
          size: 36,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;

  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _SpotifyPill extends StatelessWidget {
  final String url;

  const _SpotifyPill({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1DB954).withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        border: Border.all(
          color: const Color(0xFF1DB954).withOpacity(0.3),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note_rounded, size: 12, color: Color(0xFF1DB954)),
          SizedBox(width: 5),
          Text(
            'Spotify',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1DB954),
            ),
          ),
        ],
      ),
    );
  }
}
