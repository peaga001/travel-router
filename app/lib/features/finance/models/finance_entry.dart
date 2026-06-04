import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum FinanceCategory {
  hospedagem,
  alimentacao,
  transporte,
  passeios,
  compras,
  emergencia,
  outros;

  String get label => switch (this) {
        FinanceCategory.hospedagem => 'Hospedagem',
        FinanceCategory.alimentacao => 'Alimentação',
        FinanceCategory.transporte => 'Transporte',
        FinanceCategory.passeios => 'Passeios',
        FinanceCategory.compras => 'Compras',
        FinanceCategory.emergencia => 'Emergência',
        FinanceCategory.outros => 'Outros',
      };

  IconData get icon => switch (this) {
        FinanceCategory.hospedagem => Icons.hotel_rounded,
        FinanceCategory.alimentacao => Icons.restaurant_rounded,
        FinanceCategory.transporte => Icons.directions_car_rounded,
        FinanceCategory.passeios => Icons.explore_rounded,
        FinanceCategory.compras => Icons.shopping_bag_rounded,
        FinanceCategory.emergencia => Icons.emergency_rounded,
        FinanceCategory.outros => Icons.more_horiz_rounded,
      };

  Color get color => switch (this) {
        FinanceCategory.hospedagem => AppColors.catHospedagem,
        FinanceCategory.alimentacao => AppColors.catAlimentacao,
        FinanceCategory.transporte => AppColors.catTransporte,
        FinanceCategory.passeios => AppColors.catPasseios,
        FinanceCategory.compras => AppColors.catCompras,
        FinanceCategory.emergencia => AppColors.catEmergencia,
        FinanceCategory.outros => AppColors.catOutros,
      };
}

class FinanceEntry {
  final String id;
  final double amount;
  final FinanceCategory category;
  final String description;
  final DateTime date;
  final String? observations;

  const FinanceEntry({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.observations,
  });

  factory FinanceEntry.fromJson(Map<String, dynamic> json) {
    return FinanceEntry(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: FinanceCategory.values.firstWhere(
        (c) => c.name == (json['category'] as String),
        orElse: () => FinanceCategory.outros,
      ),
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      observations: json['observations'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category.name,
        'description': description,
        'date': date.toIso8601String(),
        'observations': observations,
      };
}

class FinanceState {
  final double initialBalance;
  final List<FinanceEntry> entries;

  const FinanceState({
    required this.initialBalance,
    this.entries = const [],
  });

  double get totalSpent =>
      entries.fold(0.0, (sum, e) => sum + e.amount);

  double get currentBalance => initialBalance - totalSpent;

  Map<FinanceCategory, double> get byCategory {
    final map = <FinanceCategory, double>{};
    for (final e in entries) {
      map[e.category] = (map[e.category] ?? 0.0) + e.amount;
    }
    return map;
  }

  FinanceState copyWith({
    double? initialBalance,
    List<FinanceEntry>? entries,
  }) {
    return FinanceState(
      initialBalance: initialBalance ?? this.initialBalance,
      entries: entries ?? this.entries,
    );
  }
}
