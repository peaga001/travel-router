import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../models/timeline_event.dart';
import '../models/trip.dart';
import '../providers/timeline_provider.dart';
import '../providers/trip_provider.dart';
import 'widgets/timeline_event_card.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(timelineProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _TripHeader(
            eventsAsync: eventsAsync,
            selectedTab: _selectedTab,
            onTabChanged: (i) => setState(() => _selectedTab = i),
          ),
          if (_selectedTab == 0) ...[
            _AtualTab(
              eventsAsync: eventsAsync,
              onTripCompleted: () => setState(() => _selectedTab = 1),
            ),
          ] else ...[
            const _CompletedTripsTab(),
          ],
        ],
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: () => _showAddEventSheet(context),
              tooltip: 'Adicionar momento',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _showAddEventSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEventSheet(ref: ref),
    );
  }
}

// ─── Sliver Header ──────────────────────────────────────────────────────────

class _TripHeader extends StatelessWidget {
  final AsyncValue<List<TimelineEvent>> eventsAsync;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const _TripHeader({
    required this.eventsAsync,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final events = eventsAsync.valueOrNull ?? [];
    final completed = events.where((e) => e.isCompleted).length;
    final total = events.length;

    return SliverAppBar(
      expandedHeight: 190,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      actions: [
        if (selectedTab == 0 && events.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Exportar PDF',
            onPressed: () => _exportPdf(context, events),
          ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text('Nossa Viagem', style: tt.displaySmall),
                  ),
                  const Text('❤️', style: TextStyle(fontSize: 24)),
                ],
              ),
              if (selectedTab == 0 && total > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('$completed de $total momentos', style: tt.bodySmall),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total > 0 ? completed / total : 0,
                          backgroundColor: AppColors.outline,
                          color: AppColors.primary,
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _TripSegmentedControl(
                selected: selectedTab,
                onChanged: onTabChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportPdf(
      BuildContext context, List<TimelineEvent> events) async {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Nossa Viagem — Álbum de Memórias',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 16),
          ...events.map(
            (e) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(e.title,
                              style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(dateFmt.format(e.dateTime),
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey600)),
                        ],
                      ),
                      if (e.location != null) ...[
                        pw.SizedBox(height: 4),
                        pw.Text('📍 ${e.location!.name}',
                            style: const pw.TextStyle(
                                fontSize: 11, color: PdfColors.grey700)),
                      ],
                      if (e.description != null &&
                          e.description!.isNotEmpty) ...[
                        pw.SizedBox(height: 8),
                        pw.Text(e.description!,
                            style: const pw.TextStyle(fontSize: 12)),
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
      name: 'viagem_surpresa.pdf',
    );
  }
}

// ─── Segmented Control ──────────────────────────────────────────────────────

class _TripSegmentedControl extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _TripSegmentedControl({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = (constraints.maxWidth - 4) / 2;

        return Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppConstants.radiusPill),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                left: selected == 0 ? 2 : tabWidth + 2,
                top: 2,
                bottom: 2,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusPill - 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onBackground.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _SegmentTab(
                    label: 'Atual',
                    isSelected: selected == 0,
                    onTap: () => onChanged(0),
                  ),
                  _SegmentTab(
                    label: 'Concluídas',
                    isSelected: selected == 1,
                    onTap: () => onChanged(1),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primaryDark
                  : AppColors.muted,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

// ─── Atual Tab ──────────────────────────────────────────────────────────────

class _AtualTab extends StatelessWidget {
  final AsyncValue<List<TimelineEvent>> eventsAsync;
  final VoidCallback onTripCompleted;

  const _AtualTab({
    required this.eventsAsync,
    required this.onTripCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return const SliverFillRemaining(
            child: EmptyStateWidget(
              emoji: '✈️',
              title: 'Nenhum momento ainda',
              subtitle: 'Adicione o primeiro evento da sua viagem surpresa!',
            ),
          );
        }

        final allCompleted = events.isNotEmpty && events.every((e) => e.isCompleted);

        return SliverPadding(
          padding: const EdgeInsets.only(left: 16, right: 0, top: 8, bottom: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < events.length) {
                  return TimelineEventCard(
                    event: events[index],
                    isFirst: index == 0,
                    isLast: index == events.length - 1,
                  );
                }
                // Last item: conclude trip section
                return Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8, bottom: 80),
                  child: _ConcludeTripSection(
                    allCompleted: allCompleted,
                    onCompleted: onTripCompleted,
                  ),
                );
              },
              childCount: events.length + 1,
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
        ),
      ),
      error: (e, _) => SliverFillRemaining(
        child: EmptyStateWidget(
          emoji: '😕',
          title: 'Algo deu errado',
          subtitle: e.toString(),
        ),
      ),
    );
  }
}

// ─── Conclude Trip Section ──────────────────────────────────────────────────

class _ConcludeTripSection extends StatelessWidget {
  final bool allCompleted;
  final VoidCallback onCompleted;

  const _ConcludeTripSection({
    required this.allCompleted,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: allCompleted
            ? AppColors.gold.withOpacity(0.07)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: allCompleted
              ? AppColors.gold.withOpacity(0.4)
              : AppColors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                allCompleted ? '🎉' : '⏳',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  allCompleted
                      ? 'Todos os momentos vividos!'
                      : 'Marque todos os momentos como vividos',
                  style: tt.titleSmall?.copyWith(
                    color: allCompleted
                        ? AppColors.primaryDark
                        : AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (!allCompleted) ...[
            const SizedBox(height: 6),
            Text(
              'Quando todos os momentos forem marcados como vividos, você poderá concluir a viagem.',
              style: tt.bodySmall?.copyWith(color: AppColors.muted, height: 1.5),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: allCompleted
                  ? () => _showConcludeSheet(context, onCompleted)
                  : null,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Concluir Viagem'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                disabledBackgroundColor: AppColors.outline,
                disabledForegroundColor: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConcludeSheet(
      BuildContext context, VoidCallback onCompleted) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConcludeTripSheet(onCompleted: onCompleted),
    );
    if (result == true) {
      onCompleted();
    }
  }
}

// ─── Conclude Trip Sheet ────────────────────────────────────────────────────

class _ConcludeTripSheet extends ConsumerStatefulWidget {
  final VoidCallback onCompleted;

  const _ConcludeTripSheet({required this.onCompleted});

  @override
  ConsumerState<_ConcludeTripSheet> createState() => _ConcludeTripSheetState();
}

class _ConcludeTripSheetState extends ConsumerState<_ConcludeTripSheet> {
  final _nameCtrl = TextEditingController(text: 'Nossa Viagem');
  final _messageCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _conclude() async {
    setState(() => _saving = true);
    try {
      await ref.read(tripProvider.notifier).completeActiveTrip(
            name: _nameCtrl.text,
            finalMessage: _messageCtrl.text.trim().isEmpty
                ? null
                : _messageCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text('Concluir Viagem', style: tt.headlineSmall),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Dê um nome a este álbum de memórias.',
                style: tt.bodySmall?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome da viagem',
                  prefixIcon: Icon(Icons.collections_bookmark_rounded),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mensagem final (opcional)',
                  prefixIcon: Icon(Icons.favorite_border_rounded),
                  hintText: 'Uma memória que ficará para sempre...',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _conclude,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Salvar Álbum'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Completed Trips Tab ────────────────────────────────────────────────────

class _CompletedTripsTab extends ConsumerWidget {
  const _CompletedTripsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripProvider);

    return tripsAsync.when(
      data: (trips) {
        if (trips.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              emoji: '🗂️',
              title: 'Nenhum álbum ainda',
              subtitle:
                  'Quando uma viagem for concluída, ela aparecerá aqui como um álbum.',
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _CompletedTripCard(trip: trips[i]),
              childCount: trips.length,
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
        ),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(child: Text('Erro: $e')),
      ),
    );
  }
}

class _CompletedTripCard extends StatelessWidget {
  final Trip trip;

  const _CompletedTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final dateFmt = DateFormat('dd MMM yyyy', 'pt_BR');

    return GestureDetector(
      onTap: () => context.go('/timeline/completed/${trip.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secondary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative emoji watermarks
            if (trip.previewEmojis.isNotEmpty)
              ..._emojiDecorations(trip.previewEmojis),

            // Content overlay
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      trip.name,
                      style: tt.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${dateFmt.format(trip.firstEventDate)} → ${dateFmt.format(trip.lastEventDate)}',
                            style: tt.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                                AppConstants.radiusPill),
                          ),
                          child: Text(
                            '${trip.eventCount} momentos',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (trip.finalMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '"${trip.finalMessage}"',
                        style: tt.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // "Ver álbum →" chip top-right
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusPill),
                ),
                child: const Text(
                  'Ver álbum →',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _emojiDecorations(List<String> emojis) {
    const positions = [
      Offset(0.72, 0.08),
      Offset(0.85, 0.50),
      Offset(0.58, 0.65),
      Offset(0.92, 0.72),
      Offset(0.48, 0.12),
      Offset(0.95, 0.22),
    ];

    return emojis.take(positions.length).toList().asMap().entries.map((e) {
      final pos = positions[e.key];
      return Positioned(
        left: 320 * pos.dx,
        top: 150 * pos.dy,
        child: Opacity(
          opacity: 0.2,
          child: Text(e.value, style: const TextStyle(fontSize: 28)),
        ),
      );
    }).toList();
  }
}

// ─── Add Event Sheet ────────────────────────────────────────────────────────

class _AddEventSheet extends StatefulWidget {
  final WidgetRef ref;

  const _AddEventSheet({required this.ref});

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _observationsCtrl = TextEditingController();
  final _spotifyCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _emojisCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _observationsCtrl.dispose();
    _spotifyCtrl.dispose();
    _tagsCtrl.dispose();
    _emojisCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final emojis = _emojisCtrl.text
        .split(' ')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final event = TimelineEvent(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      dateTime: _selectedDate,
      description: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      emojis: emojis,
      spotifyUrl: _spotifyCtrl.text.trim().isEmpty
          ? null
          : _spotifyCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : LocationData(name: _locationCtrl.text.trim()),
      observations: _observationsCtrl.text.trim().isEmpty
          ? null
          : _observationsCtrl.text.trim(),
      tags: tags,
    );

    await widget.ref.read(timelineProvider.notifier).add(event);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final dateFmt = DateFormat('dd/MM/yyyy • HH:mm', 'pt_BR');
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollCtrl) {
          return Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Novo Momento', style: tt.headlineSmall),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Título *',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Obrigatório' : null,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusMd),
                            border: Border.all(color: AppColors.outline),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  color: AppColors.muted, size: 20),
                              const SizedBox(width: 12),
                              Text(dateFmt.format(_selectedDate),
                                  style: tt.bodyMedium),
                              const Spacer(),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.muted),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                        maxLines: 3,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _emojisCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Emojis (separados por espaço)',
                          prefixIcon: Icon(Icons.emoji_emotions_rounded),
                          hintText: '❤️ ✈️ 🌅',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _locationCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Local',
                          prefixIcon: Icon(Icons.location_on_rounded),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _spotifyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Link Spotify',
                          prefixIcon: Icon(Icons.music_note_rounded),
                          hintText: 'https://open.spotify.com/...',
                        ),
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _tagsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tags (separadas por vírgula)',
                          prefixIcon: Icon(Icons.label_rounded),
                          hintText: 'jantar, romântico',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _observationsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Observações',
                          prefixIcon: Icon(Icons.info_outline_rounded),
                        ),
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Adicionar Momento'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
