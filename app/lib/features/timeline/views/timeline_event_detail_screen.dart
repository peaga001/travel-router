import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../models/timeline_event.dart';
import '../providers/timeline_provider.dart';

class TimelineEventDetailScreen extends ConsumerWidget {
  final String eventId;

  const TimelineEventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(timelineEventProvider(eventId));

    return eventAsync.when(
      data: (event) {
        if (event == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Evento não encontrado')),
          );
        }
        return _EventDetailView(event: event);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Erro: $e')),
      ),
    );
  }
}

class _EventDetailView extends ConsumerWidget {
  final TimelineEvent event;

  const _EventDetailView({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final dateFmt = DateFormat('EEEE, dd \'de\' MMMM \'de\' yyyy • HH:mm', 'pt_BR');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Photos hero header
          if (event.photos.isNotEmpty)
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: AppColors.background,
              actions: [_DeleteButton(event: event)],
              flexibleSpace: FlexibleSpaceBar(
                background: _PhotosGallery(photos: event.photos),
              ),
            )
          else
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              title: Text(event.title),
              actions: [_DeleteButton(event: event)],
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emojis
                  if (event.emojis.isNotEmpty) ...[
                    Text(
                      event.emojis.join('  '),
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Title
                  Text(event.title, style: tt.displaySmall),

                  const SizedBox(height: 12),

                  // Date
                  _InfoRow(
                    icon: Icons.access_time_rounded,
                    text: dateFmt.format(event.dateTime),
                  ),

                  // Location
                  if (event.location != null) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      text: event.location!.name,
                      color: AppColors.primary,
                    ),
                  ],

                  if (event.description != null &&
                      event.description!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Descrição', style: tt.labelMedium),
                    const SizedBox(height: 6),
                    Text(event.description!, style: tt.bodyLarge),
                  ],

                  if (event.observations != null &&
                      event.observations!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Observações', style: tt.labelMedium),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMd),
                      ),
                      child: Text(event.observations!, style: tt.bodyMedium),
                    ),
                  ],

                  // Spotify
                  if (event.spotifyUrl != null) ...[
                    const SizedBox(height: 24),
                    _SpotifyCard(url: event.spotifyUrl!),
                  ],

                  // Tags
                  if (event.tags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Tags', style: tt.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: event.tags
                          .map((tag) => Chip(
                                label: Text(tag),
                                backgroundColor:
                                    AppColors.primaryLight.withOpacity(0.4),
                                side: BorderSide.none,
                                labelStyle: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Mark as complete
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => ref
                          .read(timelineProvider.notifier)
                          .toggleCompleted(event.id),
                      icon: Icon(
                        event.isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: event.isCompleted
                            ? AppColors.success
                            : AppColors.muted,
                      ),
                      label: Text(
                        event.isCompleted
                            ? 'Marcar como pendente'
                            : 'Marcar como vivido',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: event.isCompleted
                            ? AppColors.success
                            : AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotosGallery extends StatefulWidget {
  final List<PhotoItem> photos;

  const _PhotosGallery({required this.photos});

  @override
  State<_PhotosGallery> createState() => _PhotosGalleryState();
}

class _PhotosGalleryState extends State<_PhotosGallery> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (context, i) {
            final photo = widget.photos[i];
            return Stack(
              fit: StackFit.expand,
              children: [
                photo.url.startsWith('assets/')
                    ? Image.asset(photo.url, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(
                          Icons.image_rounded,
                          color: AppColors.primaryLight,
                          size: 64,
                        ),
                      ),
                if (photo.emojiOverlay != null)
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: Text(
                      photo.emojiOverlay!,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
              ],
            );
          },
        ),
        if (widget.photos.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.photos.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _current == i
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.color = AppColors.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _SpotifyCard extends StatelessWidget {
  final String url;

  const _SpotifyCard({required this.url});

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1DB954).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(
            color: const Color(0xFF1DB954).withOpacity(0.3),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.music_note_rounded,
              color: Color(0xFF1DB954),
              size: 28,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Música do Momento',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1DB954),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Toque para abrir no Spotify',
                    style: TextStyle(
                      color: Color(0xFF1DB954),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              color: Color(0xFF1DB954),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteButton extends ConsumerWidget {
  final TimelineEvent event;

  const _DeleteButton({required this.event});

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir momento'),
        content: Text(
          'Remover "${event.title}" da sua timeline?\n\nEssa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(timelineProvider.notifier).delete(event.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.delete_outline_rounded),
      tooltip: 'Excluir momento',
      onPressed: () => _confirm(context, ref),
    );
  }
}
