import 'package:spend_wise/features/transactions/models/finance_models.dart';
import 'package:spend_wise/shared/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('transaction tile presents expense details', (tester) async {
    final item = FinanceTransaction(
      id: '1',
      type: TransactionType.expense,
      amount: 450,
      categoryId: 'food',
      description: 'Lunch',
      date: DateTime(2026, 7, 20),
      createdAt: DateTime(2026, 7, 20),
    );
    const category = FinanceCategory(
      id: 'food',
      name: 'Food',
      type: TransactionType.expense,
      icon: 0xe56c,
      color: 0xFFFF7043,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionTile(
            transaction: item,
            category: category,
            currency: 'INR',
          ),
        ),
      ),
    );
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.textContaining('Food'), findsOneWidget);
    expect(find.textContaining('450'), findsOneWidget);
  });
}
