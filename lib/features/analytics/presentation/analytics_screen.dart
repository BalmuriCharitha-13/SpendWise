import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/finance_calculator.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../../transactions/models/finance_models.dart';

enum AnalyticsPeriod { current, previous, custom }

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  AnalyticsPeriod period = AnalyticsPeriod.current;
  DateTimeRange? custom;
  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider).value ?? [];
    final categories = ref.watch(categoriesProvider).value ?? [];
    final currency = ref.watch(settingsProvider).currency;
    final now = DateTime.now();
    final (start, end) = switch (period) {
      AnalyticsPeriod.current => (
        DateTime(now.year, now.month),
        DateTime(
          now.year,
          now.month + 1,
        ).subtract(const Duration(microseconds: 1)),
      ),
      AnalyticsPeriod.previous => (
        DateTime(now.year, now.month - 1),
        DateTime(now.year, now.month).subtract(const Duration(microseconds: 1)),
      ),
      AnalyticsPeriod.custom => (
        custom?.start ?? DateTime(now.year, now.month),
        custom?.end
                .add(const Duration(days: 1))
                .subtract(const Duration(microseconds: 1)) ??
            now,
      ),
    };
    final filtered = transactions
        .where((item) => !item.date.isBefore(start) && !item.date.isAfter(end))
        .toList();
    final income = FinanceCalculator.income(filtered);
    final expense = FinanceCalculator.expenses(filtered);
    final grouped = FinanceCalculator.byCategory(filtered, start, end);
    final top =
        filtered.where((item) => item.type == TransactionType.expense).toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          SegmentedButton<AnalyticsPeriod>(
            segments: const [
              ButtonSegment(
                value: AnalyticsPeriod.current,
                label: Text('This month'),
              ),
              ButtonSegment(
                value: AnalyticsPeriod.previous,
                label: Text('Previous'),
              ),
              ButtonSegment(
                value: AnalyticsPeriod.custom,
                label: Text('Custom'),
              ),
            ],
            selected: {period},
            showSelectedIcon: false,
            onSelectionChanged: (value) async {
              final selected = value.first;
              if (selected == AnalyticsPeriod.custom) {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: now,
                  initialDateRange: custom,
                );
                if (picked == null) return;
                custom = picked;
              }
              setState(() => period = selected);
            },
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _ComparisonStat(
                  label: 'Income',
                  value: income,
                  currency: currency,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ComparisonStat(
                  label: 'Expenses',
                  value: expense,
                  currency: currency,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const SectionHeader(title: 'Income vs expense'),
          const SizedBox(height: 12),
          AppCard(
            child: SizedBox(
              height: 190,
              child: BarChart(
                BarChartData(
                  maxY:
                      [income, expense, 1].reduce((a, b) => a > b ? a : b) *
                      1.25,
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
                        getTitlesWidget: (value, _) =>
                            Text(value == 0 ? 'Income' : 'Expense'),
                      ),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: income,
                          color: Colors.teal,
                          width: 40,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: expense,
                          color: Theme.of(context).colorScheme.error,
                          width: 40,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          const SectionHeader(title: 'Spending by category'),
          const SizedBox(height: 12),
          grouped.isEmpty
              ? const AppCard(
                  child: EmptyState(
                    icon: Icons.donut_large_rounded,
                    title: 'Nothing to chart',
                    message: 'Expense categories will appear here.',
                  ),
                )
              : AppCard(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 210,
                        child: PieChart(
                          PieChartData(
                            centerSpaceRadius: 55,
                            sectionsSpace: 3,
                            sections: grouped.entries.map((entry) {
                              final category = categories
                                  .where((item) => item.id == entry.key)
                                  .firstOrNull;
                              return PieChartSectionData(
                                value: entry.value,
                                color: Color(category?.color ?? 0xFF78909C),
                                radius: 35,
                                title:
                                    '${(entry.value / expense * 100).round()}%',
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      ...grouped.entries.map((entry) {
                        final category = categories
                            .where((item) => item.id == entry.key)
                            .firstOrNull;
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 6,
                            backgroundColor: Color(
                              category?.color ?? 0xFF78909C,
                            ),
                          ),
                          title: Text(category?.name ?? 'Unknown'),
                          trailing: Text(
                            money(entry.value, currency: currency),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
          const SizedBox(height: 26),
          const SectionHeader(title: 'Highest spending'),
          const SizedBox(height: 12),
          AppCard(
            child: top.isEmpty
                ? const Text('No expenses in this period.')
                : Column(
                    children: top
                        .take(5)
                        .map(
                          (item) => TransactionTile(
                            transaction: item,
                            category: categories
                                .where(
                                  (category) => category.id == item.categoryId,
                                )
                                .firstOrNull,
                            currency: currency,
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonStat extends StatelessWidget {
  const _ComparisonStat({
    required this.label,
    required this.value,
    required this.currency,
    required this.color,
  });
  final String label;
  final double value;
  final String currency;
  final Color color;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
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
