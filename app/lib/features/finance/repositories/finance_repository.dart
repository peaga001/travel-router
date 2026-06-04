import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../models/finance_entry.dart';

const _balanceKey = '__initial_balance__';

class FinanceRepository {
  Future<FinanceState> load() async {
    final box = await Hive.openBox<String>(AppConstants.financeBox);
    await _seedIfEmpty(box);

    final balanceRaw = box.get(_balanceKey);
    final initialBalance =
        balanceRaw != null ? double.tryParse(balanceRaw) ?? 5000.0 : 5000.0;

    final entries = box.keys
        .where((k) => k != _balanceKey && k != AppConstants.seedFlagKey)
        .map((k) => FinanceEntry.fromJson(
            jsonDecode(box.get(k as String)!) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return FinanceState(initialBalance: initialBalance, entries: entries);
  }

  Future<void> saveEntry(FinanceEntry entry) async {
    final box = await Hive.openBox<String>(AppConstants.financeBox);
    await box.put(entry.id, jsonEncode(entry.toJson()));
  }

  Future<void> deleteEntry(String id) async {
    final box = await Hive.openBox<String>(AppConstants.financeBox);
    await box.delete(id);
  }

  Future<void> setInitialBalance(double amount) async {
    final box = await Hive.openBox<String>(AppConstants.financeBox);
    await box.put(_balanceKey, amount.toString());
  }

  Future<void> _seedIfEmpty(Box<String> box) async {
    if (box.get(AppConstants.seedFlagKey) != null) return;

    try {
      final jsonStr =
          await rootBundle.loadString(AppConstants.financeDataPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      await box.put(_balanceKey,
          ((data['initialBalance'] as num?) ?? 5000).toString());

      for (final e in (data['entries'] as List? ?? [])) {
        final map = e as Map<String, dynamic>;
        await box.put(map['id'] as String, jsonEncode(map));
      }
    } catch (_) {
      await box.put(_balanceKey, '5000.0');
    }

    await box.put(AppConstants.seedFlagKey, 'true');
  }
}
