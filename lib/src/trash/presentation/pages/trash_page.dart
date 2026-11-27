import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/components/common.dart';
import 'package:lab11/components/view_state_view.dart';
import 'package:lab11/constants/app_theme.dart';
import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/di/injection.dart';
import 'package:lab11/src/tasks/domain/entities/task.dart';
import 'package:lab11/src/tasks/presentation/widgets/task_card.dart';
import 'package:lab11/src/trash/presentation/bloc/trash_cubit.dart';

/// Корзина: удалённые задачи (soft delete) — восстановление или полное удаление.
class TrashPage extends StatelessWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TrashCubit>(),
      child: BlocBuilder<TrashCubit, ViewState<List<TaskDetails>>>(
        builder: (context, state) {
          final cubit = context.read<TrashCubit>();
          final count = state is ViewLoaded<List<TaskDetails>>
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
            body: ViewStateView<List<TaskDetails>>(
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
                      TaskCard(item: item, onTap: () {}),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Text(
                              'Удалена ${fmtDateTime(item.task.deletedAt!)}',
                              style: const TextStyle(
                                color: Tf.muted,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => runGuarded(
                                context,
                                () => cubit.restore(item.task.id),
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
                                    () => cubit.deleteForever(item.task.id),
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
