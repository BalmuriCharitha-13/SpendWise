import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/utils/finance_calculator.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../../transactions/models/finance_models.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionState = ref.watch(transactionsProvider);
    final categoryState = ref.watch(categoriesProvider);
    final budgetState = ref.watch(budgetsProvider);
    final summary = ref.watch(currentSummaryProvider);
    final currency = ref.watch(settingsProvider).currency;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transaction/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add transaction'),
      ),
      body: SafeArea(
        child: transactionState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load your money',
            message: 'Please close and reopen SpendWise.',
          ),
          data: (transactions) {
            final categories = categoryState.value ?? [];
            final budgets = budgetState.value ?? [];
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(transactionsProvider.notifier).refresh(),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                    sliver: SliverList.list(
                      children: [
                        Text(
                          'Good ${_greeting()} 👋',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Your money, made clear',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Chip(label: Text(monthName(DateTime.now()))),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _BalanceCard(summary: summary, currency: currency),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStat(
                                label: 'Income',
                                value: summary.income,
                                icon: Icons.south_west_rounded,
                                color: Colors.teal,
                                currency: currency,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniStat(
                                label: 'Expenses',
                                value: summary.expenses,
                                icon: Icons.north_east_rounded,
                                color: Theme.of(context).colorScheme.error,
                                currency: currency,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        const SectionHeader(title: 'Spending overview'),
                        const SizedBox(height: 12),
                        _SpendingChart(transactions: transactions),
                        const SizedBox(height: 26),
                        SectionHeader(
                          title: 'Recent transactions',
                          action: TextButton(
                            onPressed: () => context.go('/transactions'),
                            child: const Text('See all'),
                          ),
                        ),
                        AppCard(
                          child: transactions.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text('No transactions yet.'),
                                )
                              : Column(
                                  children: transactions.take(4).map((item) {
                                    return TransactionTile(
                                      transaction: item,
                                      category: _category(
                                        categories,
                                        item.categoryId,
                                      ),
                                      currency: currency,
                                      onTap: () => context.push(
                                        '/transaction/${item.id}',
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 26),
                        const SectionHeader(title: 'Budget pulse'),
                        const SizedBox(height: 12),
                        _BudgetPulse(
                          summary: summary,
                          budgets: budgets,
                          transactions: transactions,
                          categories: categories,
                          currency: currency,
                        ),
                        const SizedBox(height: 26),
                        const SectionHeader(title: 'Smart insights'),
                        const SizedBox(height: 12),
                        ...InsightService.generate(
                          transactions,
                          categories,
                          budgets,
                          DateTime.now(),
                        ).map(
                          (text) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(text)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

FinanceCategory? _category(List<FinanceCategory> list, String id) =>
    list.where((item) => item.id == id).firstOrNull;

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary, required this.currency});
  final FinanceSummary summary;
  final String currency;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        colors: [Color(0xFF5B5BD6), Color(0xFF818CF8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x335B5BD6),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TOTAL BALANCE',
          style: TextStyle(color: Colors.white70, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        FittedBox(
          child: Text(
            money(summary.balance, currency: currency),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 34,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Monthly budget',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            Text(
              '${summary.spendingPercentage.toStringAsFixed(0)}% used',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (summary.spendingPercentage / 100).clamp(0, 1),
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          backgroundColor: Colors.white24,
          color: summary.spendingPercentage > 100
              ? const Color(0xFFFFB4AB)
              : Colors.white,
        ),
      ],
    ),
  );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.currency,
  });
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final String currency;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          foregroundColor: color,
          child: Icon(icon),
        ),
        const SizedBox(height: 16),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 3),
        FittedBox(
          child: Text(
            money(value, currency: currency),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _SpendingChart extends StatelessWidget {
  const _SpendingChart({required this.transactions});
  final List<FinanceTransaction> transactions;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final values = List.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day - (6 - index));
      return transactions
          .where(
            (item) =>
                item.type == TransactionType.expense &&
                item.date.year == day.year &&
                item.date.month == day.month &&
                item.date.day == day.day,
          )
          .fold<double>(0, (sum, item) => sum + item.amount);
    });
    final max = values.fold<double>(1, (a, b) => a > b ? a : b);
    return AppCard(
      child: SizedBox(
        height: 190,
        child: BarChart(
          BarChartData(
            maxY: max * 1.25,
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      ['M', 'T', 'W', 'T', 'F', 'S', 'S'][value.toInt() % 7],
                    ),
                  ),
                ),
              ),
            ),
            barGroups: List.generate(
              values.length,
              (index) => BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: values[index],
                    color: Theme.of(context).colorScheme.primary,
                    width: 16,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetPulse extends StatelessWidget {
  const _BudgetPulse({
    required this.summary,
    required this.budgets,
    required this.transactions,
    required this.categories,
    required this.currency,
  });
  final FinanceSummary summary;
  final List<Budget> budgets;
  final List<FinanceTransaction> transactions;
  final List<FinanceCategory> categories;
  final String currency;
  @override
  Widget build(BuildContext context) {
    final exceeded = summary.spendingPercentage > 100;
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: (exceeded ? Colors.red : Colors.green)
                    .withValues(alpha: .12),
                child: Icon(
                  exceeded ? Icons.warning_rounded : Icons.shield_rounded,
                  color: exceeded ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exceeded ? 'Budget exceeded' : 'You’re on track',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${money(summary.remainingBudget.abs(), currency: currency)} '
                      '${exceeded ? 'over' : 'remaining'}',
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.go('/budgets'),
                child: const Text('Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
