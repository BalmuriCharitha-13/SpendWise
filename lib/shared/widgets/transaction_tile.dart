import 'package:flutter/material.dart';

import '../../core/utils/category_icons.dart';
import '../../core/utils/formatters.dart';
import '../../features/transactions/models/finance_models.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.currency,
    this.onTap,
  });
  final FinanceTransaction transaction;
  final FinanceCategory? category;
  final String currency;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final income = transaction.type == TransactionType.income;
    final color = category == null
        ? Theme.of(context).colorScheme.primary
        : Color(category!.color);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .14),
        foregroundColor: color,
        child: Icon(
          categoryIcon(category?.icon ?? Icons.wallet_rounded.codePoint),
        ),
      ),
      title: Text(
        transaction.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${category?.name ?? 'Unknown'} • ${shortDate(transaction.date)}',
      ),
      trailing: Text(
        '${income ? '+' : '-'}${money(transaction.amount, currency: currency)}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: income ? Colors.teal : Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
