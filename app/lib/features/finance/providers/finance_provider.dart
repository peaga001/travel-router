import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/finance_entry.dart';
import '../repositories/finance_repository.dart';

final financeRepositoryProvider =
    Provider<FinanceRepository>((ref) => FinanceRepository());

final financeProvider =
    AsyncNotifierProvider<FinanceNotifier, FinanceState>(
  FinanceNotifier.new,
);

class FinanceNotifier extends AsyncNotifier<FinanceState> {
  FinanceRepository get _repo => ref.read(financeRepositoryProvider);

  @override
  Future<FinanceState> build() => _repo.load();

  Future<void> addEntry(FinanceEntry entry) async {
    await _repo.saveEntry(entry);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteEntry(String id) async {
    await _repo.deleteEntry(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> setInitialBalance(double amount) async {
    await _repo.setInitialBalance(amount);
    ref.invalidateSelf();
    await future;
  }
}
