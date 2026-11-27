import 'package:flutter/material.dart';

import 'package:lab11/components/common.dart';
import 'package:lab11/constants/app_theme.dart';
import 'package:lab11/core/bloc/view_state.dart';

/// Единое отображение состояний Loading / Error / Empty / Loaded.
class ViewStateView<T> extends StatelessWidget {
  const ViewStateView({
    super.key,
    required this.state,
    required this.builder,
    this.onRetry,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyText = 'Пока ничего нет',
    this.emptyAction,
  });

  final ViewState<T> state;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final IconData emptyIcon;
  final String emptyText;
  final Widget? emptyAction;

  @override
  Widget build(BuildContext context) => switch (state) {
    ViewInitial() ||
    ViewLoading() => const Center(child: CircularProgressIndicator()),
    ViewEmpty() => EmptyState(
      icon: emptyIcon,
      text: emptyText,
      action: emptyAction,
    ),
    ViewError(:final message) => ErrorView(message: message, onRetry: onRetry),
    ViewLoaded(:final data) => builder(data),
  };
}

/// Ошибка: понятный текст + кнопка повторной загрузки.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      text: message,
      action: onRetry == null
          ? null
          : FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Tf.primary,
                minimumSize: const Size(160, 46),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
    );
  }
}
