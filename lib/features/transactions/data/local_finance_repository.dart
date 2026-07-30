import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/finance_models.dart';

class LocalFinanceRepository {
  LocalFinanceRepository(this._transactions, this._categories, this._budgets);
  static const transactionsBox = 'transactions';
  static const categoriesBox = 'categories';
  static const budgetsBox = 'budgets';

  final Box<dynamic> _transactions;
  final Box<dynamic> _categories;
  final Box<dynamic> _budgets;

  static Future<LocalFinanceRepository> open() async {
    await Hive.initFlutter();
    return LocalFinanceRepository(
      await Hive.openBox<dynamic>(transactionsBox),
      await Hive.openBox<dynamic>(categoriesBox),
      await Hive.openBox<dynamic>(budgetsBox),
    );
  }

  List<FinanceTransaction> getTransactions() =>
      _transactions.values
          .map((value) => FinanceTransaction.fromMap(value as Map))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  List<FinanceCategory> getCategories() => _categories.values
      .map((value) => FinanceCategory.fromMap(value as Map))
      .toList();
  List<Budget> getBudgets() =>
      _budgets.values.map((value) => Budget.fromMap(value as Map)).toList();

  Future<void> saveTransaction(FinanceTransaction item) =>
      _transactions.put(item.id, item.toMap());
  Future<void> deleteTransaction(String id) => _transactions.delete(id);
  Future<void> saveCategory(FinanceCategory item) =>
      _categories.put(item.id, item.toMap());
  Future<void> deleteCategory(String id) => _categories.delete(id);
  Future<void> saveBudget(Budget item) => _budgets.put(item.id, item.toMap());
  Future<void> deleteBudget(String id) => _budgets.delete(id);

  Future<void> clearAll() async {
    await Future.wait([
      _transactions.clear(),
      _categories.clear(),
      _budgets.clear(),
    ]);
  }

  Future<void> seed({bool force = false}) async {
    if (force) await clearAll();
    if (_categories.isNotEmpty) return;
    final expenseNames = [
      ('food', 'Food', Icons.restaurant_rounded, 0xFFFF7043),
      ('transport', 'Transport', Icons.directions_car_rounded, 0xFF42A5F5),
      ('shopping', 'Shopping', Icons.shopping_bag_rounded, 0xFFAB47BC),
      ('entertainment', 'Entertainment', Icons.movie_rounded, 0xFFEC407A),
      ('bills', 'Bills', Icons.receipt_long_rounded, 0xFFFFB300),
      ('health', 'Health', Icons.favorite_rounded, 0xFFEF5350),
      ('education', 'Education', Icons.school_rounded, 0xFF5C6BC0),
      ('travel', 'Travel', Icons.flight_rounded, 0xFF26A69A),
      ('other_expense', 'Other', Icons.more_horiz_rounded, 0xFF78909C),
    ];
    final incomeNames = [
      ('salary', 'Salary', Icons.payments_rounded, 0xFF26A69A),
      ('freelance', 'Freelance', Icons.laptop_mac_rounded, 0xFF66BB6A),
      ('business', 'Business', Icons.business_center_rounded, 0xFF29B6F6),
      ('investment', 'Investment', Icons.trending_up_rounded, 0xFF7E57C2),
      ('other_income', 'Other', Icons.add_circle_rounded, 0xFF78909C),
    ];
    for (final item in expenseNames) {
      await saveCategory(
        FinanceCategory(
          id: item.$1,
          name: item.$2,
          type: TransactionType.expense,
          icon: item.$3.codePoint,
          color: item.$4,
          isDefault: true,
        ),
      );
    }
    for (final item in incomeNames) {
      await saveCategory(
        FinanceCategory(
          id: item.$1,
          name: item.$2,
          type: TransactionType.income,
          icon: item.$3.codePoint,
          color: item.$4,
          isDefault: true,
        ),
      );
    }
    final now = DateTime.now();
    final samples = [
      ('t1', TransactionType.income, 85000.0, 'salary', 'Monthly salary', 2),
      ('t2', TransactionType.expense, 2450.0, 'food', 'Weekly groceries', 3),
      ('t3', TransactionType.expense, 1299.0, 'bills', 'Internet bill', 5),
      ('t4', TransactionType.expense, 780.0, 'transport', 'Fuel', 7),
      ('t5', TransactionType.expense, 1890.0, 'shopping', 'Running shoes', 10),
      (
        't6',
        TransactionType.income,
        12000.0,
        'freelance',
        'Design project',
        12,
      ),
      (
        't7',
        TransactionType.expense,
        650.0,
        'entertainment',
        'Movie night',
        14,
      ),
      (
        't8',
        TransactionType.expense,
        3200.0,
        'food',
        'Dinner with friends',
        17,
      ),
    ];
    for (final item in samples) {
      final date = now.subtract(Duration(days: item.$6));
      await saveTransaction(
        FinanceTransaction(
          id: item.$1,
          type: item.$2,
          amount: item.$3,
          categoryId: item.$4,
          description: item.$5,
          date: date,
          createdAt: date,
        ),
      );
    }
    for (final item in [
      ('food', 10000.0),
      ('shopping', 6000.0),
      ('transport', 5000.0),
      ('entertainment', 3000.0),
    ]) {
      await saveBudget(
        Budget(
          id: 'budget_${item.$1}_${now.year}_${now.month}',
          categoryId: item.$1,
          amount: item.$2,
          month: DateTime(now.year, now.month),
          createdAt: now,
        ),
      );
    }
  }
}
