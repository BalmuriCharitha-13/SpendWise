import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/transactions/data/local_finance_repository.dart';
import '../features/transactions/models/finance_models.dart';
import 'utils/finance_calculator.dart';

final repositoryProvider = Provider<LocalFinanceRepository>(
  (ref) => throw UnimplementedError('Repository must be initialized'),
);

class TransactionsNotifier extends AsyncNotifier<List<FinanceTransaction>> {
  LocalFinanceRepository get _repo => ref.read(repositoryProvider);
  @override
  Future<List<FinanceTransaction>> build() async => _repo.getTransactions();
  Future<void> save(FinanceTransaction item) async {
    await _repo.saveTransaction(item);
    state = AsyncData(_repo.getTransactions());
  }

  Future<void> remove(String id) async {
    await _repo.deleteTransaction(id);
    state = AsyncData(_repo.getTransactions());
  }

  Future<void> refresh() async => state = AsyncData(_repo.getTransactions());
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<FinanceTransaction>>(
      TransactionsNotifier.new,
    );

class CategoriesNotifier extends AsyncNotifier<List<FinanceCategory>> {
  LocalFinanceRepository get _repo => ref.read(repositoryProvider);
  @override
  Future<List<FinanceCategory>> build() async => _repo.getCategories();
  Future<void> save(FinanceCategory item) async {
    await _repo.saveCategory(item);
    state = AsyncData(_repo.getCategories());
  }

  Future<void> remove(String id) async {
    await _repo.deleteCategory(id);
    state = AsyncData(_repo.getCategories());
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<FinanceCategory>>(
      CategoriesNotifier.new,
    );

class BudgetsNotifier extends AsyncNotifier<List<Budget>> {
  LocalFinanceRepository get _repo => ref.read(repositoryProvider);
  @override
  Future<List<Budget>> build() async => _repo.getBudgets();
  Future<void> save(Budget item) async {
    await _repo.saveBudget(item);
    state = AsyncData(_repo.getBudgets());
  }

  Future<void> remove(String id) async {
    await _repo.deleteBudget(id);
    state = AsyncData(_repo.getBudgets());
  }
}

final budgetsProvider = AsyncNotifierProvider<BudgetsNotifier, List<Budget>>(
  BudgetsNotifier.new,
);

final currentSummaryProvider = Provider<FinanceSummary>((ref) {
  final items = ref.watch(transactionsProvider).value ?? [];
  final budgets = ref.watch(budgetsProvider).value ?? [];
  return FinanceCalculator.summary(items, budgets, DateTime.now());
});

enum ThemePreference { system, light, dark }

class SettingsState {
  const SettingsState({
    this.theme = ThemePreference.system,
    this.currency = 'INR',
  });
  final ThemePreference theme;
  final String currency;
  ThemeMode get themeMode => switch (theme) {
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
    ThemePreference.system => ThemeMode.system,
  };
}

class SettingsNotifier extends Notifier<SettingsState> {
  SharedPreferences get _prefs => ref.read(preferencesProvider);
  @override
  SettingsState build() {
    final theme = ThemePreference.values.byName(
      _prefs.getString('theme') ?? ThemePreference.system.name,
    );
    return SettingsState(
      theme: theme,
      currency: _prefs.getString('currency') ?? 'INR',
    );
  }

  Future<void> setTheme(ThemePreference value) async {
    state = SettingsState(theme: value, currency: state.currency);
    await _prefs.setString('theme', value.name);
  }

  Future<void> setCurrency(String value) async {
    state = SettingsState(theme: state.theme, currency: value);
    await _prefs.setString('currency', value);
  }
}

final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Preferences must be initialized'),
);
final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
