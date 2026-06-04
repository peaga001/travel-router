import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../models/checklist_item.dart';
import '../providers/checklist_provider.dart';

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  ChecklistCategory? _filterCategory;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final itemsAsync = ref.watch(checklistProvider);
    final progress = ref.watch(checklistProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: false,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Checklist', style: tt.displaySmall),
                    const SizedBox(height: 10),
                    _ProgressBar(
                      total: progress.total,
                      completed: progress.completed,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Category filter
          SliverToBoxAdapter(
            child: _CategoryFilter(
              selected: _filterCategory,
              onSelected: (cat) =>
                  setState(() => _filterCategory = cat),
            ),
          ),

          itemsAsync.when(
            data: (allItems) {
              final items = _filterCategory == null
                  ? allItems
                  : allItems
                      .where((i) => i.category == _filterCategory)
                      .toList();

              if (items.isEmpty && allItems.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyStateWidget(
                    emoji: '✅',
                    title: 'Tudo pronto!',
                    subtitle:
                        'Sua lista está vazia. Adicione itens para a sua viagem.',
                  ),
                );
              }

              if (items.isEmpty) {
                return SliverFillRemaining(
                  child: EmptyStateWidget(
                    emoji: '🔍',
                    title: 'Nenhum item',
                    subtitle: 'Nenhum item nesta categoria.',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 8, bottom: 96),
                sliver: _filterCategory == null
                    ? _GroupedList(items: items)
                    : _FlatList(items: items),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Erro: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        tooltip: 'Adicionar item',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(ref: ref),
    );
  }
}

// ─── Progress Bar ───────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int total;
  final int completed;

  const _ProgressBar({required this.total, required this.completed});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final pct = total > 0 ? (completed / total * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$completed de $total itens', style: tt.bodySmall),
            Text('$pct%',
                style: tt.labelMedium
                    ?.copyWith(color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? completed / total : 0,
            backgroundColor: AppColors.outline,
            color: AppColors.primary,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ─── Category Filter ────────────────────────────────────────────────────────

class _CategoryFilter extends StatelessWidget {
  final ChecklistCategory? selected;
  final ValueChanged<ChecklistCategory?> onSelected;

  const _CategoryFilter({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: 'Todos',
            icon: Icons.list_rounded,
            color: AppColors.primary,
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          ...ChecklistCategory.values.map(
            (cat) => _FilterChip(
              label: cat.label,
              icon: cat.icon,
              color: cat.color,
              isSelected: selected == cat,
              onTap: () =>
                  onSelected(selected == cat ? null : cat),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusPill),
          border: Border.all(
            color: isSelected ? color : AppColors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Grouped List ────────────────────────────────────────────────────────────

class _GroupedList extends ConsumerWidget {
  final List<ChecklistItem> items;

  const _GroupedList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = <ChecklistCategory, List<ChecklistItem>>{};
    for (final cat in ChecklistCategory.values) {
      final catItems = items.where((i) => i.category == cat).toList();
      if (catItems.isNotEmpty) grouped[cat] = catItems;
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final entry = grouped.entries.toList()[i];
          return _CategorySection(
            category: entry.key,
            items: entry.value,
          );
        },
        childCount: grouped.length,
      ),
    );
  }
}

class _FlatList extends ConsumerWidget {
  final List<ChecklistItem> items;

  const _FlatList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _ChecklistTile(item: items[i]),
        childCount: items.length,
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final ChecklistCategory category;
  final List<ChecklistItem> items;

  const _CategorySection({required this.category, required this.items});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final completed = items.where((i) => i.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(category.icon, size: 15, color: category.color),
              ),
              const SizedBox(width: 10),
              Text(category.label, style: tt.titleSmall),
              const Spacer(),
              Text(
                '$completed/${items.length}',
                style: tt.bodySmall?.copyWith(color: category.color),
              ),
            ],
          ),
        ),
        ...items.map((item) => _ChecklistTile(item: item)),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _ChecklistTile extends ConsumerWidget {
  final ChecklistItem item;

  const _ChecklistTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.error,
        ),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) =>
          ref.read(checklistProvider.notifier).delete(item.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(
            color: item.isCompleted
                ? AppColors.success.withOpacity(0.3)
                : AppColors.outline,
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: GestureDetector(
            onTap: () =>
                ref.read(checklistProvider.notifier).toggle(item.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isCompleted
                    ? AppColors.success
                    : Colors.transparent,
                border: Border.all(
                  color: item.isCompleted
                      ? AppColors.success
                      : AppColors.outline,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: item.isCompleted
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ),
          title: Text(
            item.title,
            style: tt.bodyMedium?.copyWith(
              color: item.isCompleted
                  ? AppColors.muted
                  : AppColors.onBackground,
              decoration: item.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          subtitle: item.notes != null && item.notes!.isNotEmpty
              ? Text(item.notes!, style: tt.bodySmall)
              : null,
          trailing: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: item.category.color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover item'),
        content: Text('Remover "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

// ─── Add Item Sheet ─────────────────────────────────────────────────────────

class _AddItemSheet extends StatefulWidget {
  final WidgetRef ref;

  const _AddItemSheet({required this.ref});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  ChecklistCategory _category = ChecklistCategory.extras;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final items = widget.ref.read(checklistProvider).valueOrNull ?? [];
    final item = ChecklistItem(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      category: _category,
      order: items.length,
      notes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
    );

    await widget.ref.read(checklistProvider.notifier).add(item);
    if (mounted) Navigator.pop(context);
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            const SizedBox(height: 16),
            Text('Novo Item', style: tt.headlineSmall),
            const SizedBox(height: 16),

            TextFormField(
              controller: _titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Item *',
                prefixIcon: Icon(Icons.add_task_rounded),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),

            // Category picker
            Text('Categoria', style: tt.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ChecklistCategory.values.map((cat) {
                final sel = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          sel ? cat.color : cat.color.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusPill),
                      border: Border.all(
                        color: sel
                            ? cat.color
                            : cat.color.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon,
                            size: 13,
                            color: sel ? Colors.white : cat.color),
                        const SizedBox(width: 5),
                        Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : cat.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
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
                            color: Colors.white),
                      )
                    : const Text('Adicionar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
