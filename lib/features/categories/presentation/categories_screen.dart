import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/category_icons.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../transactions/models/finance_models.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});
  static const icons = [
    Icons.restaurant_rounded,
    Icons.shopping_bag_rounded,
    Icons.home_rounded,
    Icons.sports_esports_rounded,
    Icons.flight_rounded,
    Icons.pets_rounded,
    Icons.local_cafe_rounded,
    Icons.work_rounded,
  ];
  static const colors = [
    0xFF5B5BD6,
    0xFF26A69A,
    0xFFFF7043,
    0xFF42A5F5,
    0xFFAB47BC,
    0xFFEC407A,
    0xFFFFB300,
    0xFF78909C,
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoriesProvider);
    final transactions = ref.watch(transactionsProvider).value ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Custom category'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Categories unavailable',
          message: 'Please try again.',
        ),
        data: (categories) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: TransactionType.values
              .map(
                (type) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                      child: Text(
                        type == TransactionType.expense
                            ? 'EXPENSE CATEGORIES'
                            : 'INCOME CATEGORIES',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Card(
                      child: Column(
                        children: categories
                            .where((item) => item.type == type)
                            .map(
                              (item) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Color(
                                    item.color,
                                  ).withValues(alpha: .14),
                                  child: Icon(
                                    categoryIcon(item.icon),
                                    color: Color(item.color),
                                  ),
                                ),
                                title: Text(item.name),
                                subtitle: Text(
                                  item.isDefault ? 'Built in' : 'Custom',
                                ),
                                trailing: item.isDefault
                                    ? const Icon(Icons.lock_outline_rounded)
                                    : PopupMenuButton<String>(
                                        onSelected: (action) => action == 'edit'
                                            ? _edit(
                                                context,
                                                ref,
                                                category: item,
                                              )
                                            : _delete(
                                                context,
                                                ref,
                                                item,
                                                transactions,
                                              ),
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    FinanceCategory? category,
  }) async {
    final name = TextEditingController(text: category?.name ?? '');
    var type = category?.type ?? TransactionType.expense;
    var icon = category?.icon ?? icons.first.codePoint;
    var color = category?.color ?? colors.first;
    final key = GlobalKey<FormState>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => Padding(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: category == null ? 'New category' : 'Edit category',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Enter a category name'
                      : null,
                ),
                const SizedBox(height: 14),
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Expense'),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Income'),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: category == null
                      ? (value) => update(() => type = value.first)
                      : null,
                ),
                const SizedBox(height: 18),
                Text('Icon', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: icons
                      .map(
                        (value) => IconButton.filledTonal(
                          isSelected: icon == value.codePoint,
                          onPressed: () => update(() => icon = value.codePoint),
                          icon: Icon(value),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                Text('Color', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: colors
                      .map(
                        (value) => InkWell(
                          onTap: () => update(() => color = value),
                          borderRadius: BorderRadius.circular(20),
                          child: CircleAvatar(
                            backgroundColor: Color(value),
                            child: color == value
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!key.currentState!.validate()) return;
                      final now = DateTime.now();
                      await ref
                          .read(categoriesProvider.notifier)
                          .save(
                            FinanceCategory(
                              id:
                                  category?.id ??
                                  'custom_${now.microsecondsSinceEpoch}',
                              name: name.text.trim(),
                              type: type,
                              icon: icon,
                              color: color,
                            ),
                          );
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save category'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    name.dispose();
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    FinanceCategory category,
    List<FinanceTransaction> transactions,
  ) async {
    if (transactions.any((item) => item.categoryId == category.id)) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Category in use'),
          content: const Text(
            'Reassign or delete its transactions before deleting this category.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return;
    }
    await ref.read(categoriesProvider.notifier).remove(category.id);
  }
}
