import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/finance_calculator.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../transactions/models/finance_models.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budgetsProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];
    final transactions = ref.watch(transactionsProvider).value ?? [];
    final currency = ref.watch(settingsProvider).currency;
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly budgets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editBudget(context, ref, categories),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New budget'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Budgets unavailable',
          message: 'Your budget data could not be loaded.',
        ),
        data: (budgets) {
          final monthly = budgets
              .where(
                (item) =>
                    FinanceCalculator.sameMonth(item.month, DateTime.now()),
              )
              .toList();
          return monthly.isEmpty
              ? EmptyState(
                  icon: Icons.savings_outlined,
                  title: 'Plan your month',
                  message:
                      'Create category budgets to stay ahead of your spending.',
                  action: FilledButton(
                    onPressed: () => _editBudget(context, ref, categories),
                    child: const Text('Create a budget'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    Text(
                      monthName(DateTime.now()),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Set boundaries without losing sight of the big picture.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    ...monthly.map((budget) {
                      final category = categories
                          .where((item) => item.id == budget.categoryId)
                          .firstOrNull;
                      final spent = transactions
                          .where(
                            (item) =>
                                item.type == TransactionType.expense &&
                                item.categoryId == budget.categoryId &&
                                FinanceCalculator.sameMonth(
                                  item.date,
                                  budget.month,
                                ),
                          )
                          .fold<double>(0, (sum, item) => sum + item.amount);
                      return _BudgetCard(
                        budget: budget,
                        category: category,
                        spent: spent,
                        currency: currency,
                        onTap: () => _editBudget(
                          context,
                          ref,
                          categories,
                          budget: budget,
                        ),
                        onDelete: () => _delete(context, ref, budget),
                      );
                    }),
                  ],
                );
        },
      ),
    );
  }

  Future<void> _editBudget(
    BuildContext context,
    WidgetRef ref,
    List<FinanceCategory> categories, {
    Budget? budget,
  }) async {
    final expense = categories
        .where((item) => item.type == TransactionType.expense)
        .toList();
    var categoryId = budget?.categoryId;
    final controller = TextEditingController(
      text: budget?.amount.toStringAsFixed(0) ?? '',
    );
    final key = GlobalKey<FormState>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SectionHeader(
                title: budget == null ? 'Create budget' : 'Edit budget',
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: categoryId,
                decoration: const InputDecoration(
                  labelText: 'Expense category',
                ),
                items: expense
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => categoryId = value,
                validator: (value) =>
                    value == null ? 'Choose a category' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Monthly limit'),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  return parsed == null || parsed <= 0
                      ? 'Enter a valid limit'
                      : null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!key.currentState!.validate()) return;
                    final now = DateTime.now();
                    await ref
                        .read(budgetsProvider.notifier)
                        .save(
                          Budget(
                            id:
                                budget?.id ??
                                'budget_${categoryId}_${now.year}_${now.month}',
                            categoryId: categoryId!,
                            amount: double.parse(controller.text),
                            month: DateTime(now.year, now.month),
                            createdAt: budget?.createdAt ?? now,
                          ),
                        );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save budget'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete budget?'),
        content: const Text(
          'Transactions in this category will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(budgetsProvider.notifier).remove(budget.id);
    }
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.category,
    required this.spent,
    required this.currency,
    required this.onTap,
    required this.onDelete,
  });
  final Budget budget;
  final FinanceCategory? category;
  final double spent;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final progress = spent / budget.amount;
    final color = progress >= 1
        ? Colors.red
        : progress >= .8
        ? Colors.orange
        : Colors.green;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(
                    category?.color ?? 0xFF78909C,
                  ).withValues(alpha: .14),
                  child: Icon(
                    categoryIcon(
                      category?.icon ?? Icons.category_rounded.codePoint,
                    ),
                    color: Color(category?.color ?? 0xFF78909C),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category?.name ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        progress >= 1
                            ? 'Exceeded'
                            : progress >= .8
                            ? 'Near limit'
                            : 'Safe',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => value == 'edit' ? onTap() : onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 9,
              borderRadius: BorderRadius.circular(6),
              color: color,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text('${money(spent, currency: currency)} spent'),
                ),
                Text(
                  '${money(budget.amount, currency: currency)} limit',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
