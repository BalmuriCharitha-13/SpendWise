import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
        children: [
          const _Label('Appearance'),
          Card(
            child: Column(
              children: [
                RadioGroup<ThemePreference>(
                  groupValue: settings.theme,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).setTheme(value);
                    }
                  },
                  child: Column(
                    children: [
                      ...ThemePreference.values.map(
                        (value) => RadioListTile(
                          value: value,
                          title: Text(switch (value) {
                            ThemePreference.system => 'Use system theme',
                            ThemePreference.light => 'Light theme',
                            ThemePreference.dark => 'Dark theme',
                          }),
                          secondary: Icon(switch (value) {
                            ThemePreference.system =>
                              Icons.brightness_auto_rounded,
                            ThemePreference.light => Icons.light_mode_rounded,
                            ThemePreference.dark => Icons.dark_mode_rounded,
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const _Label('Preferences'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange_rounded),
                  title: const Text('Currency'),
                  subtitle: Text(settings.currency),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _currency(context, ref, settings.currency),
                ),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Manage categories'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/categories'),
                ),
              ],
            ),
          ),
          const _Label('Data'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.restart_alt_rounded),
                  title: const Text('Reset sample data'),
                  subtitle: const Text(
                    'Restore the original demo transactions',
                  ),
                  onTap: () => _reset(context, ref),
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_sweep_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Clear all data',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () => _clear(context, ref),
                ),
              ],
            ),
          ),
          const _Label('SpendWise'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('About app'),
              subtitle: const Text('Version 1.0.0'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/about'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _currency(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['INR', 'USD', 'EUR', 'GBP']
              .map(
                (currency) => ListTile(
                  leading: Icon(
                    currency == current
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                  ),
                  title: Text(currency),
                  onTap: () => Navigator.pop(context, currency),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null) {
      await ref.read(settingsProvider.notifier).setCurrency(selected);
    }
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String message,
  ) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    if (!await _confirm(
      context,
      'Reset sample data?',
      'This replaces all current data with the original demo data.',
    )) {
      return;
    }
    await ref.read(repositoryProvider).seed(force: true);
    ref.invalidate(transactionsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(budgetsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sample data restored')));
    }
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    if (!await _confirm(
      context,
      'Clear all data?',
      'Transactions, categories, and budgets will be permanently removed.',
    )) {
      return;
    }
    await ref.read(repositoryProvider).clearAll();
    ref.invalidate(transactionsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(budgetsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All local data cleared')));
    }
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    ),
  );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 46,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SpendWise',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Text('Version 1.0.0'),
            const SizedBox(height: 24),
            const Text(
              'A private, offline-first personal finance companion that helps you '
              'understand spending, shape budgets, and make confident decisions.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Chip(
              label: Text(
                'Flutter • Material 3 • Riverpod • GoRouter • Hive • fl_chart',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
