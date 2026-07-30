# SpendWise Project Learning Guide

## Suggested study order

1. `lib/features/transactions/models/finance_models.dart`
2. `lib/features/transactions/data/local_finance_repository.dart`
3. `lib/core/providers.dart`
4. `lib/core/utils/finance_calculator.dart`
5. `lib/main.dart` and `lib/core/router/app_router.dart`
6. Transaction form/list, then dashboard, budgets, analytics, and settings
7. `test/finance_calculator_test.dart`

## Concepts used

Flutter concepts include immutable widgets, stateful forms, controllers,
validation, responsive scrolling, dialogs, sheets, pickers, Material 3 themes,
and reusable composition. Dart concepts include enums, immutable classes,
factory constructors, records, collection transforms, null safety, extensions
such as `firstOrNull`, async/await, and pattern matching.

Riverpod provides dependency injection, async collection state, mutations, and
derived values. GoRouter uses a `StatefulShellRoute.indexedStack` so each bottom
tab preserves its navigation and scroll state. Hive stores typed model maps in
three device-local boxes. SharedPreferences is intentionally limited to small
settings.

## Repository and state flow

`LocalFinanceRepository` is the only layer that knows about Hive. Providers
receive it through `repositoryProvider`. A notifier reads or writes the
repository and publishes a new `AsyncData` list. Widgets watch that provider
and rebuild automatically. Dashboard calculations are derived rather than
stored, preventing stale totals.

```text
user action
  → presentation widget
  → Riverpod notifier method
  → LocalFinanceRepository
  → Hive box
  → notifier publishes fresh list
  → watched providers recalculate
  → Flutter rebuilds affected widgets
```

## Feature walkthroughs

### Transactions

1. UI starts in `TransactionsScreen` or `TransactionFormScreen`.
2. `TransactionsNotifier` handles collection state.
3. It calls `LocalFinanceRepository.saveTransaction` or `deleteTransaction`.
4. Maps are stored by ID in the `transactions` Hive box.
5. The notifier reloads and publishes an `AsyncData<List<FinanceTransaction>>`.
6. The list, dashboard, analytics, and budget screens rebuild because they
   watch `transactionsProvider`.

Search and filters remain presentation state because they do not change stored
data. `FinanceCalculator.filter` contains the reusable filtering rules.

### Dashboard and insights

1. UI starts in `DashboardScreen`.
2. It watches transaction/category/budget providers and
   `currentSummaryProvider`.
3. No repository is called directly by the screen.
4. Source records already live in Hive.
5. `FinanceCalculator.summary` and `InsightService.generate` derive values.
6. Any underlying provider change triggers a targeted rebuild.

### Budgets

1. UI starts in `BudgetsScreen`.
2. `BudgetsNotifier` owns state.
3. It calls budget save/delete methods in `LocalFinanceRepository`.
4. Budget maps are keyed by ID in the `budgets` box.
5. A fresh list is published after every mutation.
6. Budget cards and the dashboard budget pulse update automatically.

Spent amounts are calculated from matching expense transactions for the
budget's category and month. Progress below 80% is safe, 80–99% is near the
limit, and 100% or more is exceeded.

### Analytics

1. UI starts in `AnalyticsScreen`.
2. It watches transactions, categories, and settings.
3. No write repository call is needed.
4. Data originates in Hive through the async notifiers.
5. Period selection filters records; `FinanceCalculator` groups and totals.
6. fl_chart widgets rebuild with the resulting values.

### Categories

1. UI starts in `CategoriesScreen`.
2. `CategoriesNotifier` owns state.
3. It calls category save/delete repository methods.
4. Category maps live in the `categories` box.
5. The notifier publishes the updated collection.
6. dropdowns, icons, analytics legends, and transaction rows rebuild.

Built-in categories are locked. A custom category cannot be deleted while a
transaction references it, preserving referential integrity.

### Settings and initialization

1. `main.dart` initializes Flutter, Hive, seed data, and preferences before UI.
2. `SettingsNotifier` owns theme and currency state.
3. It uses SharedPreferences, while data reset uses the finance repository.
4. Preferences are key/value settings; finance records remain in Hive.
5. Updating settings publishes a new immutable `SettingsState`.
6. `SpendWiseApp` rebuilds theme mode; money widgets rebuild currency output.

## Important design decisions

- Explicit map serialization avoids build_runner complexity.
- Totals and analytics are derived, never duplicated in storage.
- IDs are stable and records are immutable.
- Repository injection makes storage replaceable and testable.
- Feature folders show ownership without excessive layers.
- Local filters use widget state; shared business rules use pure services.

## Interview questions

- Why use a repository between Riverpod and Hive?
- What is the difference between source state and derived state?
- Why should dashboard totals not be persisted?
- How does watching a provider cause Flutter to rebuild?
- When would `AsyncNotifier` be preferable to `Notifier`?
- How does the stateful GoRouter shell preserve tab state?
- How is a transaction converted to and from a Hive-compatible map?
- How does category deletion protect existing transactions?
- What would change to support cloud sync or authentication?
- Which services can be unit-tested without Flutter bindings, and why?
