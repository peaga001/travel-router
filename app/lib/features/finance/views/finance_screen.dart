import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../models/finance_entry.dart';
import '../providers/finance_provider.dart';

final _currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _dateFmt = DateFormat('dd/MM/yy', 'pt_BR');

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(financeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: stateAsync.when(
        data: (state) => _FinanceBody(state: state),
        loading: () => const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2),
        ),
        error: (e, _) => EmptyStateWidget(
          emoji: '😕',
          title: 'Erro ao carregar',
          subtitle: e.toString(),
        ),
      ),
      floatingActionButton: stateAsync.hasValue
          ? FloatingActionButton(
              onPressed: () => _showAddExpenseSheet(context, ref),
              tooltip: 'Adicionar gasto',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _showAddExpenseSheet(
      BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExpenseSheet(ref: ref),
    );
  }
}

class _FinanceBody extends ConsumerWidget {
  final FinanceState state;

  const _FinanceBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: false,
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          title: Text('Financeiro', style: tt.headlineMedium),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Ajustar orçamento',
              onPressed: () => _showSetBudgetDialog(context, ref, state),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _SummaryCards(state: state),
          ),
        ),

        if (state.entries.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: _CategoryChart(state: state),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Histórico', style: tt.titleMedium),
            ),
          ),
          SliverPadding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 96),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) =>
                    _ExpenseTile(entry: state.entries[i]),
                childCount: state.entries.length,
              ),
            ),
          ),
        ] else
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              emoji: '💰',
              title: 'Nenhum gasto registrado',
              subtitle:
                  'Adicione seu primeiro gasto para ver o dashboard.',
            ),
          ),
      ],
    );
  }

  Future<void> _showSetBudgetDialog(
      BuildContext context, WidgetRef ref, FinanceState state) async {
    final ctrl = TextEditingController(
        text: state.initialBalance.toStringAsFixed(2).replaceAll('.', ','));
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Orçamento inicial'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Valor (R\$)',
            prefixIcon: Icon(Icons.account_balance_wallet_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final text =
                  ctrl.text.trim().replaceAll(',', '.');
              final amount = double.tryParse(text);
              if (amount != null) {
                ref
                    .read(financeProvider.notifier)
                    .setInitialBalance(amount);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Cards ──────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final FinanceState state;

  const _SummaryCards({required this.state});

  @override
  Widget build(BuildContext context) {
    final balanceColor = state.currentBalance >= 0
        ? AppColors.success
        : AppColors.error;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Orçamento',
                value: _currencyFmt.format(state.initialBalance),
                icon: Icons.savings_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Gasto',
                value: _currencyFmt.format(state.totalSpent),
                icon: Icons.receipt_long_rounded,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          label: 'Saldo disponível',
          value: _currencyFmt.format(state.currentBalance),
          icon: Icons.account_balance_rounded,
          color: balanceColor,
          highlight: true,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlight;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? color.withOpacity(0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
          color: highlight ? color.withOpacity(0.3) : AppColors.outline,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusMd),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: tt.labelSmall),
                Text(
                  value,
                  style: tt.titleMedium?.copyWith(
                    color: highlight ? color : AppColors.onBackground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Chart ─────────────────────────────────────────────────────────

class _CategoryChart extends StatefulWidget {
  final FinanceState state;

  const _CategoryChart({required this.state});

  @override
  State<_CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends State<_CategoryChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final byCategory = widget.state.byCategory;
    if (byCategory.isEmpty) return const SizedBox.shrink();

    final total = widget.state.totalSpent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gastos por Categoria', style: tt.titleSmall),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            setState(() => _touched = -1);
                            return;
                          }
                          setState(() => _touched = response
                              .touchedSection!.touchedSectionIndex);
                        },
                      ),
                      sections: byCategory.entries
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        final i = entry.key;
                        final cat = entry.value.key;
                        final amount = entry.value.value;
                        final pct = total > 0
                            ? (amount / total * 100).round()
                            : 0;
                        final isTouched = i == _touched;

                        return PieChartSectionData(
                          color: cat.color,
                          value: amount,
                          title: '$pct%',
                          radius: isTouched ? 68 : 56,
                          titleStyle: TextStyle(
                            fontSize: isTouched ? 13 : 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: byCategory.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: e.key.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            e.key.label,
                            style: tt.bodySmall?.copyWith(
                              color: AppColors.onBackground,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _currencyFmt.format(e.value),
                            style: tt.labelSmall,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Expense Tile ────────────────────────────────────────────────────────────

class _ExpenseTile extends ConsumerWidget {
  final FinanceEntry entry;

  const _ExpenseTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remover gasto'),
          content: Text('Remover "${entry.description}"?'),
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
      ),
      onDismissed: (_) =>
          ref.read(financeProvider.notifier).deleteEntry(entry.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(color: AppColors.outline),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: entry.category.color.withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusMd),
            ),
            child: Icon(entry.category.icon,
                size: 20, color: entry.category.color),
          ),
          title: Text(entry.description, style: tt.bodyMedium),
          subtitle: Text(
            '${entry.category.label} · ${_dateFmt.format(entry.date)}',
            style: tt.bodySmall,
          ),
          trailing: Text(
            _currencyFmt.format(entry.amount),
            style: tt.titleSmall?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Add Expense Sheet ───────────────────────────────────────────────────────

class _AddExpenseSheet extends StatefulWidget {
  final WidgetRef ref;

  const _AddExpenseSheet({required this.ref});

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  FinanceCategory _category = FinanceCategory.alimentacao;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final desc = _descCtrl.text.trim();
    final amountText =
        _amountCtrl.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (desc.isEmpty || amount == null || amount <= 0) return;
    setState(() => _saving = true);

    final entry = FinanceEntry(
      id: const Uuid().v4(),
      amount: amount,
      category: _category,
      description: desc,
      date: _date,
      observations: _obsCtrl.text.trim().isEmpty
          ? null
          : _obsCtrl.text.trim(),
    );

    await widget.ref.read(financeProvider.notifier).addEntry(entry);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');

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
            Text('Novo Gasto', style: tt.headlineSmall),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountCtrl,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Valor *',
                      prefixText: 'R\$ ',
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMd),
                      border: Border.all(color: AppColors.outline),
                    ),
                    child: Text(
                      dateFmt.format(_date),
                      style: tt.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrição *',
                prefixIcon: Icon(Icons.receipt_rounded),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // Category picker
            Text('Categoria', style: tt.labelMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: FinanceCategory.values.map((cat) {
                  final sel = _category == cat;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? cat.color
                            : cat.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                            AppConstants.radiusPill),
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
                              color:
                                  sel ? Colors.white : cat.color),
                          const SizedBox(width: 5),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : cat.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _obsCtrl,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              textInputAction: TextInputAction.done,
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
                    : const Text('Registrar Gasto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
