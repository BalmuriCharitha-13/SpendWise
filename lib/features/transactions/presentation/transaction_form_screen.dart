import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/formatters.dart';
import '../models/finance_models.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.transactionId});
  final String? transactionId;
  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController();
  final description = TextEditingController();
  final notes = TextEditingController();
  TransactionType type = TransactionType.expense;
  String? categoryId;
  DateTime date = DateTime.now();
  bool initialized = false;
  bool saving = false;
  FinanceTransaction? existing;

  @override
  void dispose() {
    amount.dispose();
    description.dispose();
    notes.dispose();
    super.dispose();
  }

  void _initialize() {
    if (initialized) return;
    initialized = true;
    if (widget.transactionId == null || widget.transactionId == 'new') return;
    existing = (ref.read(transactionsProvider).value ?? [])
        .where((item) => item.id == widget.transactionId)
        .firstOrNull;
    if (existing case final item?) {
      type = item.type;
      categoryId = item.categoryId;
      amount.text = item.amount.toStringAsFixed(2);
      description.text = item.description;
      notes.text = item.notes;
      date = item.date;
    }
  }

  @override
  Widget build(BuildContext context) {
    _initialize();
    final categories = (ref.watch(categoriesProvider).value ?? [])
        .where((item) => item.type == type)
        .toList();
    if (categoryId != null &&
        !categories.any((item) => item.id == categoryId)) {
      categoryId = null;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? 'Add transaction' : 'Edit transaction'),
        actions: [
          if (existing != null)
            IconButton(
              tooltip: 'Delete',
              onPressed: saving ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    icon: Icon(Icons.north_east_rounded),
                    label: Text('Expense'),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    icon: Icon(Icons.south_west_rounded),
                    label: Text('Income'),
                  ),
                ],
                selected: {type},
                onSelectionChanged: (value) => setState(() {
                  type = value.first;
                  categoryId = null;
                }),
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: const Key('amountField'),
                controller: amount,
                autofocus: existing == null,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  return parsed == null || parsed <= 0
                      ? 'Enter an amount greater than zero'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('categoryField'),
                initialValue: categoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Row(
                          children: [
                            Icon(
                              categoryIcon(category.icon),
                              color: Color(category.color),
                            ),
                            const SizedBox(width: 10),
                            Text(category.name),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => categoryId = value),
                validator: (value) =>
                    value == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('descriptionField'),
                controller: description,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                validator: (value) {
                  final length = value?.trim().length ?? 0;
                  if (length < 3) return 'Use at least 3 characters';
                  if (length > 80) return 'Keep it under 80 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                tileColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: .45),
                leading: const Icon(Icons.calendar_today_rounded),
                title: const Text('Date'),
                subtitle: Text(shortDate(date)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notes,
                minLines: 3,
                maxLines: 5,
                maxLength: 240,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  key: const Key('saveTransactionButton'),
                  onPressed: saving ? null : _save,
                  icon: saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    existing == null ? 'Save transaction' : 'Save changes',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    final now = DateTime.now();
    final item = FinanceTransaction(
      id: existing?.id ?? now.microsecondsSinceEpoch.toString(),
      type: type,
      amount: double.parse(amount.text),
      categoryId: categoryId!,
      description: description.text.trim(),
      notes: notes.text.trim(),
      date: date,
      createdAt: existing?.createdAt ?? now,
    );
    try {
      await ref.read(transactionsProvider.notifier).save(item);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaction saved')));
      }
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the transaction')),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This action cannot be undone.'),
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
    if (confirmed != true || existing == null) return;
    await ref.read(transactionsProvider.notifier).remove(existing!.id);
    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
    }
  }
}
