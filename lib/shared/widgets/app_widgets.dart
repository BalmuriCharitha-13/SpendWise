import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});
  final String title;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      // Dart 3.12's collection null-aware syntax is not enabled in this SDK.
      // ignore: use_null_aware_elements
      if (action case final action?) action,
    ],
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });
  final AsyncSnapshotLike<T> value;
  final Widget Function(T) data;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    if (value.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (value.error != null) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Something went wrong',
        message: 'Your local data could not be loaded.',
        action: onRetry == null
            ? null
            : FilledButton(onPressed: onRetry, child: const Text('Try again')),
      );
    }
    return data(value.data as T);
  }
}

class AsyncSnapshotLike<T> {
  const AsyncSnapshotLike({this.data, this.error, this.isLoading = false});
  final T? data;
  final Object? error;
  final bool isLoading;
}
