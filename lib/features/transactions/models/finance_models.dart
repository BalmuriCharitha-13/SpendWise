enum TransactionType { income, expense }

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.date,
    required this.createdAt,
    this.notes = '',
  });

  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String description;
  final String notes;
  final DateTime date;
  final DateTime createdAt;

  FinanceTransaction copyWith({
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? description,
    String? notes,
    DateTime? date,
  }) => FinanceTransaction(
    id: id,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    categoryId: categoryId ?? this.categoryId,
    description: description ?? this.description,
    notes: notes ?? this.notes,
    date: date ?? this.date,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'amount': amount,
    'categoryId': categoryId,
    'description': description,
    'notes': notes,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory FinanceTransaction.fromMap(Map<dynamic, dynamic> map) =>
      FinanceTransaction(
        id: map['id'] as String,
        type: TransactionType.values.byName(map['type'] as String),
        amount: (map['amount'] as num).toDouble(),
        categoryId: map['categoryId'] as String,
        description: map['description'] as String,
        notes: (map['notes'] as String?) ?? '',
        date: DateTime.parse(map['date'] as String),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

class FinanceCategory {
  const FinanceCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });
  final String id;
  final String name;
  final TransactionType type;
  final int icon;
  final int color;
  final bool isDefault;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.name,
    'icon': icon,
    'color': color,
    'isDefault': isDefault,
  };
  factory FinanceCategory.fromMap(Map<dynamic, dynamic> map) => FinanceCategory(
    id: map['id'] as String,
    name: map['name'] as String,
    type: TransactionType.values.byName(map['type'] as String),
    icon: map['icon'] as int,
    color: map['color'] as int,
    isDefault: map['isDefault'] as bool,
  );
}

class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.createdAt,
  });
  final String id;
  final String categoryId;
  final double amount;
  final DateTime month;
  final DateTime createdAt;
  Map<String, dynamic> toMap() => {
    'id': id,
    'categoryId': categoryId,
    'amount': amount,
    'month': month.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };
  factory Budget.fromMap(Map<dynamic, dynamic> map) => Budget(
    id: map['id'] as String,
    categoryId: map['categoryId'] as String,
    amount: (map['amount'] as num).toDouble(),
    month: DateTime.parse(map['month'] as String),
    createdAt: DateTime.parse(map['createdAt'] as String),
  );
}
