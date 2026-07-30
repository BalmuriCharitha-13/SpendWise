import 'package:expense_tracker/core/utils/finance_calculator.dart';
import 'package:expense_tracker/features/transactions/models/finance_models.dart';
import 'package:flutter_test/flutter_test.dart';

FinanceTransaction makeTransaction(
  String id,
  TransactionType type,
  double amount,
  String category,
  DateTime date,
) => FinanceTransaction(
  id: id,
  type: type,
  amount: amount,
  categoryId: category,
  description: 'Test transaction',
  date: date,
  createdAt: date,
);

void main() {
  final month = DateTime(2026, 7);
  final items = [
    makeTransaction('1', TransactionType.income, 5000, 'salary', month),
    makeTransaction('2', TransactionType.expense, 1200, 'food', month),
    makeTransaction('3', TransactionType.expense, 300, 'travel', month),
    makeTransaction(
      '4',
      TransactionType.expense,
      900,
      'food',
      DateTime(2026, 6),
    ),
  ];
  final budgets = [
    Budget(
      id: 'b1',
      categoryId: 'food',
      amount: 3000,
      month: month,
      createdAt: month,
    ),
  ];

  test('calculates summary and budget usage', () {
    final summary = FinanceCalculator.summary(items, budgets, month);
    expect(summary.income, 5000);
    expect(summary.expenses, 1500);
    expect(summary.balance, 3500);
    expect(summary.remainingBudget, 1500);
    expect(summary.spendingPercentage, 50);
  });

  test('groups expenses by category within the date range', () {
    final grouped = FinanceCalculator.byCategory(
      items,
      DateTime(2026, 7),
      DateTime(2026, 7, 31),
    );
    expect(grouped, {'food': 1200, 'travel': 300});
  });

  test('filters by search, type, category, and date', () {
    final result = FinanceCalculator.filter(
      items,
      query: 'test',
      type: TransactionType.expense,
      categoryId: 'food',
      start: DateTime(2026, 7),
    );
    expect(result.map((item) => item.id), ['2']);
  });

  test('generates data-driven insights', () {
    const categories = [
      FinanceCategory(
        id: 'food',
        name: 'Food',
        type: TransactionType.expense,
        icon: 1,
        color: 1,
      ),
      FinanceCategory(
        id: 'travel',
        name: 'Travel',
        type: TransactionType.expense,
        icon: 2,
        color: 2,
      ),
    ];
    final insights = InsightService.generate(items, categories, budgets, month);
    expect(insights.first, contains('Food'));
  });
}
