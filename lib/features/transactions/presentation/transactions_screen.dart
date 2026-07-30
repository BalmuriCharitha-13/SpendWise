import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/utils/finance_calculator.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../models/finance_models.dart';

enum TransactionSort { newest, oldest, highest, lowest }

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});
  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final search = TextEditingController();
  TransactionType? type;
  String? categoryId;
  DateTimeRange? range;
  TransactionSort sort = TransactionSort.newest;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];
    final currency = ref.watch(settingsProvider).currency;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            tooltip: 'Filter and sort',
            onPressed: () => _filters(categories),
            icon: Badge(
              isLabelVisible:
                  type != null || categoryId != null || range != null,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transaction/new'),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search transactions',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          if (type != null || categoryId != null || range != null)
            SizedBox(
              height: 44,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  if (type != null)
                    InputChip(
                      label: Text(type!.name),
                      onDeleted: () => setState(() => type = null),
                    ),
                  if (categoryId != null) ...[
                    const SizedBox(width: 8),
                    InputChip(
                      label: Text(
                        categories
                                .where((c) => c.id == categoryId)
                                .firstOrNull
                                ?.name ??
                            'Category',
                      ),
                      onDeleted: () => setState(() => categoryId = null),
                    ),
                  ],
                  if (range != null) ...[
                    const SizedBox(width: 8),
                    InputChip(
                      label: const Text('Date range'),
                      onDeleted: () => setState(() => range = null),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const EmptyState(
                icon: Icons.error_outline,
                title: 'Unable to load transactions',
                message: 'Pull down to try again.',
              ),
              data: (items) {
                final filtered = FinanceCalculator.filter(
                  items,
                  query: search.text,
                  type: type,
                  categoryId: categoryId,
                  start: range?.start,
                  end: range?.end
                      .add(const Duration(days: 1))
                      .subtract(const Duration(microseconds: 1)),
                );
                switch (sort) {
                  case TransactionSort.newest:
                    filtered.sort((a, b) => b.date.compareTo(a.date));
                  case TransactionSort.oldest:
                    filtered.sort((a, b) => a.date.compareTo(b.date));
                  case TransactionSort.highest:
                    filtered.sort((a, b) => b.amount.compareTo(a.amount));
                  case TransactionSort.lowest:
                    filtered.sort((a, b) => a.amount.compareTo(b.amount));
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(transactionsProvider.notifier).refresh(),
                  child: filtered.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            EmptyState(
                              icon: Icons.receipt_long_rounded,
                              title: 'No transactions found',
                              message: 'Try changing your search or filters.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return TransactionTile(
                              transaction: item,
                              category: categories
                                  .where((c) => c.id == item.categoryId)
                                  .firstOrNull,
                              currency: currency,
                              onTap: () =>
                                  context.push('/transaction/${item.id}'),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _filters(List<FinanceCategory> categories) async {
    var draftType = type;
    var draftCategory = categoryId;
    var draftSort = sort;
    DateTimeRange? draftRange = range;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionHeader(title: 'Filter & sort'),
                  const SizedBox(height: 16),
                  SegmentedButton<TransactionType?>(
                    segments: const [
                      ButtonSegment(value: null, label: Text('All')),
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('Expense'),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text('Income'),
                      ),
                    ],
                    selected: {draftType},
                    onSelectionChanged: (value) =>
                        update(() => draftType = value.first),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String?>(
                    initialValue: draftCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All categories'),
                      ),
                      ...categories.map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ),
                    ],
                    onChanged: (value) => update(() => draftCategory = value),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<TransactionSort>(
                    initialValue: draftSort,
                    decoration: const InputDecoration(labelText: 'Sort by'),
                    items: TransactionSort.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(switch (value) {
                              TransactionSort.newest => 'Newest first',
                              TransactionSort.oldest => 'Oldest first',
                              TransactionSort.highest => 'Highest amount',
                              TransactionSort.lowest => 'Lowest amount',
                            }),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => update(() => draftSort = value!),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tileColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    leading: const Icon(Icons.date_range_rounded),
                    title: Text(
                      draftRange == null ? 'Any date' : 'Custom date range',
                    ),
                    trailing: draftRange == null
                        ? null
                        : IconButton(
                            onPressed: () => update(() => draftRange = null),
                            icon: const Icon(Icons.close),
                          ),
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: draftRange,
                      );
                      if (picked != null) update(() => draftRange = picked);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          type = draftType;
                          categoryId = draftCategory;
                          sort = draftSort;
                          range = draftRange;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Apply filters'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
