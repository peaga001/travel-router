import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../models/timeline_event.dart';
import '../models/trip.dart';
import '../providers/timeline_provider.dart';
import '../providers/trip_provider.dart';
import 'widgets/timeline_event_card.dart';

class CompletedTripDetailScreen extends ConsumerWidget {
  final String tripId;

  const CompletedTripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(completedTripByIdProvider(tripId));
    final eventsAsync = ref.watch(completedTripEventsProvider(tripId));

    return tripAsync.when(
      data: (trip) {
        if (trip == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyStateWidget(
              emoji: '🗂️',
              title: 'Viagem não encontrada',
              subtitle: 'Este álbum pode ter sido removido.',
            ),
          );
        }
        return _TripDetailView(trip: trip, eventsAsync: eventsAsync);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Erro: $e')),
      ),
    );
  }
}

class _TripDetailView extends StatelessWidget {
  final Trip trip;
  final AsyncValue<List<TimelineEvent>> eventsAsync;

  const _TripDetailView({required this.trip, required this.eventsAsync});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final dateFmt = DateFormat('dd MMM yyyy', 'pt_BR');
    final events = eventsAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Collapsible Header ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.white),
                tooltip: 'Exportar PDF',
                onPressed: events.isNotEmpty
                    ? () => _exportPdf(context, trip, events)
                    : null,
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _TripHeroHeader(trip: trip),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── "Álbum Finalizado" badge ────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusPill),
                          border: Border.all(
                              color: AppColors.gold.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('✨',
                                style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 5),
                            Text(
                              'Álbum Finalizado',
                              style: tt.labelSmall?.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${trip.eventCount} momentos',
                        style: tt.bodySmall,
                      ),
                    ],
                  ),
                ),

                // ── Period ──────────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_rounded,
                          size: 14, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Text(
                        '${dateFmt.format(trip.firstEventDate)} → ${dateFmt.format(trip.lastEventDate)}',
                        style: tt.bodySmall,
                      ),
                    ],
                  ),
                ),

                // ── Final Message ────────────────────────────────────────
                if (trip.finalMessage != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: _FinalMessageCard(message: trip.finalMessage!),
                  ),
                ],

                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Events ─────────────────────────────────────────────────────
          eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateWidget(
                    emoji: '📷',
                    title: 'Nenhum momento registrado',
                    subtitle: 'Esta viagem não possui eventos salvos.',
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.only(
                    left: 16, right: 0, top: 4, bottom: 48),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => TimelineEventCard(
                      event: events[i],
                      isFirst: i == 0,
                      isLast: i == events.length - 1,
                      readOnly: true,
                    ),
                    childCount: events.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Erro: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(
      BuildContext context, Trip trip, List<TimelineEvent> events) async {
    final dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              trip.name,
              style: pw.TextStyle(
                  fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            '${dateFmt.format(trip.firstEventDate)} → ${dateFmt.format(trip.lastEventDate)}',
            style: const pw.TextStyle(
                fontSize: 12, color: PdfColors.grey600),
          ),
          if (trip.finalMessage != null) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.amber300),
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                '"${trip.finalMessage}"',
                style: pw.TextStyle(
                    fontSize: 13, fontStyle: pw.FontStyle.italic),
              ),
            ),
          ],
          pw.SizedBox(height: 20),
          ...events.map(
            (e) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(e.title,
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                            DateFormat('dd/MM/yyyy HH:mm', 'pt_BR')
                                .format(e.dateTime),
                            style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey600),
                          ),
                        ],
                      ),
                      if (e.location != null)
                        pw.Text('📍 ${e.location!.name}',
                            style: const pw.TextStyle(
                                fontSize: 11,
                                color: PdfColors.grey700)),
                      if (e.description != null &&
                          e.description!.isNotEmpty) ...[
                        pw.SizedBox(height: 6),
                        pw.Text(e.description!,
                            style:
                                const pw.TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: '${trip.name.toLowerCase().replaceAll(' ', '_')}.pdf',
    );
  }
}

// ── Hero Header ─────────────────────────────────────────────────────────────

class _TripHeroHeader extends StatelessWidget {
  final Trip trip;

  const _TripHeroHeader({required this.trip});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative emojis
          if (trip.previewEmojis.isNotEmpty)
            ..._emojiDecorations(trip.previewEmojis),

          // Content
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trip.name,
                  style: tt.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _emojiDecorations(List<String> emojis) {
    final positions = [
      const Offset(0.75, 0.15),
      const Offset(0.85, 0.55),
      const Offset(0.60, 0.70),
      const Offset(0.92, 0.80),
      const Offset(0.50, 0.20),
      const Offset(0.95, 0.25),
    ];

    return emojis.take(positions.length).toList().asMap().entries.map((e) {
      final pos = positions[e.key];
      return Positioned(
        left: MediaQueryData.fromView(
                    WidgetsBinding.instance.platformDispatcher.views.first)
                .size
                .width *
            pos.dx,
        top: 180 * pos.dy,
        child: Opacity(
          opacity: 0.25,
          child: Text(e.value,
              style: const TextStyle(fontSize: 32)),
        ),
      );
    }).toList();
  }
}

// ── Final Message Card ───────────────────────────────────────────────────────

class _FinalMessageCard extends StatelessWidget {
  final String message;

  const _FinalMessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.gold.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💌', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Mensagem Final',
                style: tt.labelMedium?.copyWith(color: AppColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"$message"',
            style: tt.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.onBackground,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
