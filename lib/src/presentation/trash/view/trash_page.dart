import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/components/common.dart';
import 'package:lab11/components/view_state_view.dart';
import 'package:lab11/constants/app_theme.dart';
import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/di/injection.dart';
import 'package:lab11/src/domain/trash/entities/trash_item.dart';
import 'package:lab11/src/presentation/tasks/widgets/task_card.dart';
import 'package:lab11/src/presentation/trash/bloc/trash_cubit.dart';

/// Корзина: удалённые задачи (soft delete) — восстановление или полное удаление.
class TrashPage extends StatelessWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TrashCubit>(),
      child: BlocBuilder<TrashCubit, ViewState<List<TrashItem>>>(
        builder: (context, state) {
          final cubit = context.read<TrashCubit>();
          final count = state is ViewLoaded<List<TrashItem>>
              ? state.data.length
              : 0;
          return GradientScaffold(
            title: 'Корзина',
            subtitle: 'Удалённые задачи: $count',
            actions: [
              if (count > 0)
                IconButton(
                  tooltip: 'Очистить корзину',
                  icon: const Icon(Icons.delete_forever_outlined),
                  onPressed: () async {
                    if (await confirm(
                          context,
                          'Очистить корзину?',
                          'Задачи будут удалены навсегда.',
                        ) &&
                        context.mounted) {
                      await runGuarded(context, cubit.emptyTrash);
                    }
                  },
                ),
            ],
            body: ViewStateView<List<TrashItem>>(
              state: state,
              onRetry: cubit.retry,
              emptyIcon: Icons.delete_outline,
              emptyText: 'Корзина пуста',
              builder: (list) => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final item = list[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TaskCard(item: item.details, onTap: () {}),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Text(
                              'Удалена ${fmtDateTime(item.deletedAt)}',
                              style: const TextStyle(
                                color: Tf.muted,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => runGuarded(
                                context,
                                () => cubit.restore(item.taskId),
                                success: 'Задача восстановлена',
                              ),
                              icon: const Icon(Icons.restore),
                              label: const Text('Восстановить'),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Tf.accent,
                              ),
                              onPressed: () async {
                                if (await confirm(
                                      context,
                                      'Удалить навсегда?',
                                      'Комментарии, вложения и история задачи тоже будут удалены.',
                                    ) &&
                                    context.mounted) {
                                  await runGuarded(
                                    context,
                                    () => cubit.deleteForever(item.taskId),
                                  );
                                }
                              },
                              icon: const Icon(Icons.delete_forever),
                              label: const Text('Навсегда'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
