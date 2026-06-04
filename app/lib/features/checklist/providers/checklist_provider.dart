import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/checklist_item.dart';
import '../repositories/checklist_repository.dart';

final checklistRepositoryProvider =
    Provider<ChecklistRepository>((ref) => ChecklistRepository());

final checklistProvider =
    AsyncNotifierProvider<ChecklistNotifier, List<ChecklistItem>>(
  ChecklistNotifier.new,
);

class ChecklistNotifier extends AsyncNotifier<List<ChecklistItem>> {
  ChecklistRepository get _repo => ref.read(checklistRepositoryProvider);

  @override
  Future<List<ChecklistItem>> build() => _repo.getAll();

  Future<void> add(ChecklistItem item) async {
    await _repo.save(item);
    ref.invalidateSelf();
    await future;
  }

  Future<void> saveItem(ChecklistItem item) async {
    await _repo.save(item);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> toggle(String id) async {
    final items = await future;
    final item = items.firstWhere((i) => i.id == id);
    await saveItem(item.copyWith(isCompleted: !item.isCompleted));
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = await future;
    final list = List<ChecklistItem>.from(current);
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = list.removeAt(oldIndex);
    list.insert(adjusted, item);
    await _repo.reorder(list);
    ref.invalidateSelf();
    await future;
  }
}

// Derived: progress stats
final checklistProgressProvider = Provider<({int total, int completed})>((ref) {
  final items = ref.watch(checklistProvider).valueOrNull ?? [];
  return (
    total: items.length,
    completed: items.where((i) => i.isCompleted).length,
  );
});
