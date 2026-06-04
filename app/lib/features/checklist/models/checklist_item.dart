import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum ChecklistCategory {
  documentos,
  roupas,
  higiene,
  eletronicos,
  remedios,
  extras;

  String get label => switch (this) {
        ChecklistCategory.documentos => 'Documentos',
        ChecklistCategory.roupas => 'Roupas',
        ChecklistCategory.higiene => 'Higiene',
        ChecklistCategory.eletronicos => 'Eletrônicos',
        ChecklistCategory.remedios => 'Remédios',
        ChecklistCategory.extras => 'Extras',
      };

  IconData get icon => switch (this) {
        ChecklistCategory.documentos => Icons.article_rounded,
        ChecklistCategory.roupas => Icons.checkroom_rounded,
        ChecklistCategory.higiene => Icons.soap_rounded,
        ChecklistCategory.eletronicos => Icons.devices_rounded,
        ChecklistCategory.remedios => Icons.medical_services_rounded,
        ChecklistCategory.extras => Icons.more_horiz_rounded,
      };

  Color get color => switch (this) {
        ChecklistCategory.documentos => AppColors.catDocumentos,
        ChecklistCategory.roupas => AppColors.catRoupas,
        ChecklistCategory.higiene => AppColors.catHigiene,
        ChecklistCategory.eletronicos => AppColors.catEletronicos,
        ChecklistCategory.remedios => AppColors.catRemedios,
        ChecklistCategory.extras => AppColors.catExtras,
      };
}

class ChecklistItem {
  final String id;
  final String title;
  final ChecklistCategory category;
  final bool isCompleted;
  final int order;
  final String? notes;

  const ChecklistItem({
    required this.id,
    required this.title,
    required this.category,
    this.isCompleted = false,
    this.order = 0,
    this.notes,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      title: json['title'] as String,
      category: ChecklistCategory.values.firstWhere(
        (c) => c.name == (json['category'] as String),
        orElse: () => ChecklistCategory.extras,
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'isCompleted': isCompleted,
        'order': order,
        'notes': notes,
      };

  ChecklistItem copyWith({
    String? id,
    String? title,
    ChecklistCategory? category,
    bool? isCompleted,
    int? order,
    Object? notes = _sentinel,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
      notes: notes == _sentinel ? this.notes : notes as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const Object _sentinel = Object();
