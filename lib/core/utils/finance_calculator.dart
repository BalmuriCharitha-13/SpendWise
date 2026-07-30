import '../../features/transactions/models/finance_models.dart';

class FinanceSummary {
  const FinanceSummary({
    required this.income,
    required this.expenses,
    required this.budget,
  });
  final double income;
  final double expenses;
  final double budget;
  double get balance => income - expenses;
  double get remainingBudget => budget - expenses;
  double get spendingPercentage =>
      budget <= 0 ? 0 : (expenses / budget * 100).clamp(0, double.infinity);
}

class FinanceCalculator {
  const FinanceCalculator._();
  static bool sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
  static double income(Iterable<FinanceTransaction> items) => items
      .where((item) => item.type == TransactionType.income)
      .fold(0, (sum, item) => sum + item.amount);
  static double expenses(Iterable<FinanceTransaction> items) => items
      .where((item) => item.type == TransactionType.expense)
      .fold(0, (sum, item) => sum + item.amount);
  static FinanceSummary summary(
    Iterable<FinanceTransaction> items,
    Iterable<Budget> budgets,
    DateTime month,
  ) {
    final monthly = items.where((item) => sameMonth(item.date, month));
    final limit = budgets
        .where((budget) => sameMonth(budget.month, month))
        .fold<double>(0, (sum, budget) => sum + budget.amount);
    return FinanceSummary(
      income: income(monthly),
      expenses: expenses(monthly),
      budget: limit,
    );
  }

  static Map<String, double> byCategory(
    Iterable<FinanceTransaction> items,
    DateTime start,
    DateTime end,
  ) {
    final result = <String, double>{};
    for (final item in items.where(
      (item) =>
          item.type == TransactionType.expense &&
          !item.date.isBefore(start) &&
          !item.date.isAfter(end),
    )) {
      result.update(
        item.categoryId,
        (value) => value + item.amount,
        ifAbsent: () => item.amount,
      );
    }
    return result;
  }

  static List<FinanceTransaction> filter(
    Iterable<FinanceTransaction> items, {
    String query = '',
    TransactionType? type,
    String? categoryId,
    DateTime? start,
    DateTime? end,
  }) {
    final normalized = query.trim().toLowerCase();
    return items.where((item) {
      return (normalized.isEmpty ||
              item.description.toLowerCase().contains(normalized) ||
              item.notes.toLowerCase().contains(normalized)) &&
          (type == null || item.type == type) &&
          (categoryId == null || item.categoryId == categoryId) &&
          (start == null || !item.date.isBefore(start)) &&
          (end == null || !item.date.isAfter(end));
    }).toList();
  }
}

class InsightService {
  const InsightService._();
  static List<String> generate(
    List<FinanceTransaction> items,
    List<FinanceCategory> categories,
    List<Budget> budgets,
    DateTime month,
  ) {
    final current = FinanceCalculator.summary(items, budgets, month);
    final previousMonth = DateTime(month.year, month.month - 1);
    final previous = FinanceCalculator.summary(items, budgets, previousMonth);
    final start = DateTime(month.year, month.month);
    final end = DateTime(
      month.year,
      month.month + 1,
    ).subtract(const Duration(microseconds: 1));
    final grouped = FinanceCalculator.byCategory(items, start, end);
    final insights = <String>[];
    if (grouped.isNotEmpty) {
      final top = grouped.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final name = categories
          .where((category) => category.id == top.key)
          .map((category) => category.name)
          .firstOrNull;
      insights.add(
        'Your highest spending category this month is ${name ?? 'Other'}.',
      );
    }
    if (previous.expenses > 0) {
      final change =
          ((current.expenses - previous.expenses) / previous.expenses * 100)
              .abs()
              .round();
      insights.add(
        'You spent $change% ${current.expenses >= previous.expenses ? 'more' : 'less'} than last month.',
      );
    }
    if (current.expenses > current.income && current.expenses > 0) {
      insights.add('Your expenses are higher than your income this month.');
    }
    for (final budget in budgets.where((b) => sameMonth(b.month, month))) {
      final spent = grouped[budget.categoryId] ?? 0;
      if (spent >= budget.amount * .85) {
        final name = categories
            .where((c) => c.id == budget.categoryId)
            .map((c) => c.name)
            .firstOrNull;
        insights.add(
          spent > budget.amount
              ? 'You exceeded your ${name ?? 'category'} budget.'
              : 'You are close to reaching your ${name ?? 'category'} budget.',
        );
      }
    }
    return insights.isEmpty
        ? ['Add a few transactions to unlock personalized financial insights.']
        : insights.take(4).toList();
  }

  static bool sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}
