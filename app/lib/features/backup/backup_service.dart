import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../checklist/providers/checklist_provider.dart';
import '../finance/providers/finance_provider.dart';
import '../timeline/providers/timeline_provider.dart';
import '../timeline/providers/trip_provider.dart';

// Conditional import: web = dart:html download / mobile = share_plus
import '_file_saver_web.dart' if (dart.library.io) '_file_saver_io.dart';

const _balanceKey = '__initial_balance__';

class BackupService {
  // ── Export ──────────────────────────────────────────────────────────────────

  Future<void> exportAll() async {
    final json = await _buildExportJson();
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .substring(0, 19);
    await saveJsonToFile(json, 'travel_surprise_$ts.json');
  }

  Future<String> _buildExportJson() async {
    final timelineBox = await Hive.openBox<String>(AppConstants.timelineBox);
    final tripsBox = await Hive.openBox<String>(AppConstants.tripsBox);
    final checklistBox = await Hive.openBox<String>(AppConstants.checklistBox);
    final financeBox = await Hive.openBox<String>(AppConstants.financeBox);

    final balanceRaw = financeBox.get(_balanceKey);
    final initialBalance =
        balanceRaw != null ? double.tryParse(balanceRaw) ?? 5000.0 : 5000.0;

    return const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'timeline': _entries(timelineBox),
      'trips': _entries(tripsBox),
      'checklist': _entries(checklistBox),
      'finance': {
        'initialBalance': initialBalance,
        'entries': _entries(financeBox, skip: {_balanceKey}),
      },
    });
  }

  List<Map<String, dynamic>> _entries(Box<String> box,
      {Set<String> skip = const {}}) {
    final ignore = {AppConstants.seedFlagKey, ...skip};
    return box.keys
        .where((k) => !ignore.contains(k as String))
        .map((k) => jsonDecode(box.get(k as String)!) as Map<String, dynamic>)
        .toList();
  }

  // ── Import ──────────────────────────────────────────────────────────────────

  /// Picks a JSON file and restores all data. Returns `true` on success.
  Future<bool> importAll(WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return false;

    final file = result.files.first;
    final String jsonStr;

    if (file.bytes != null) {
      jsonStr = utf8.decode(file.bytes!);
    } else if (file.path != null) {
      jsonStr = await readFileByPath(file.path!);
    } else {
      return false;
    }

    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    await _restore(data);

    ref.invalidate(timelineProvider);
    ref.invalidate(tripProvider);
    ref.invalidate(checklistProvider);
    ref.invalidate(financeProvider);

    return true;
  }

  Future<void> _restore(Map<String, dynamic> data) async {
    await _restoreBox(
      AppConstants.timelineBox,
      (data['timeline'] as List? ?? []).cast<Map<String, dynamic>>(),
    );
    await _restoreBox(
      AppConstants.tripsBox,
      (data['trips'] as List? ?? []).cast<Map<String, dynamic>>(),
    );
    await _restoreBox(
      AppConstants.checklistBox,
      (data['checklist'] as List? ?? []).cast<Map<String, dynamic>>(),
    );

    final finance = data['finance'] as Map<String, dynamic>? ?? {};
    final initialBalance =
        (finance['initialBalance'] as num?)?.toDouble() ?? 5000.0;
    await _restoreBox(
      AppConstants.financeBox,
      (finance['entries'] as List? ?? []).cast<Map<String, dynamic>>(),
      extras: {_balanceKey: initialBalance.toString()},
    );
  }

  Future<void> _restoreBox(
    String boxName,
    List<Map<String, dynamic>> entries, {
    Map<String, String> extras = const {},
  }) async {
    final box = await Hive.openBox<String>(boxName);
    await box.clear();
    await box.put(AppConstants.seedFlagKey, 'true');
    for (final e in entries) {
      await box.put(e['id'] as String, jsonEncode(e));
    }
    for (final kv in extras.entries) {
      await box.put(kv.key, kv.value);
    }
  }
}

final backupServiceProvider =
    Provider<BackupService>((ref) => BackupService());
