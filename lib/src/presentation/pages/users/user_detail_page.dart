import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/components/common.dart';
import 'package:lab11/components/view_state_view.dart';
import 'package:lab11/constants/app_theme.dart';
import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/di/injection.dart';
import 'package:lab11/src/presentation/bloc/home/current_user_cubit.dart';
import 'package:lab11/src/domain/entities/projects/project.dart';
import 'package:lab11/src/domain/usecases/projects/project_usecases.dart';
import 'package:lab11/src/presentation/bloc/tasks/task_list_cubit.dart';
import 'package:lab11/src/presentation/widgets/tasks/task_list_view.dart';
import 'package:lab11/src/domain/entities/users/user.dart';
import 'package:lab11/src/presentation/bloc/users/user_detail_cubit.dart';
import 'package:lab11/src/presentation/bloc/users/users_cubit.dart';
import 'package:lab11/src/presentation/pages/users/users_page.dart';

/// Профиль пользователя и все назначенные ему задачи.
class UserDetailPage extends StatelessWidget {
  const UserDetailPage({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<UserDetailCubit>(param1: userId)),
        BlocProvider(create: (_) => getIt<UsersCubit>()),
        BlocProvider(create: (_) => getIt<TaskListCubit>(param2: userId)),
        BlocProvider(
          create: (_) => StreamCubit<List<Project>>(
            () => getIt<WatchUserProjectsUseCase>()(userId),
          ),
        ),
      ],
      child: BlocBuilder<UserDetailCubit, ViewState<User?>>(
        builder: (context, state) {
          if (state is! ViewLoaded<User?>) {
            return GradientScaffold(
              title: 'Пользователь',
              body: ViewStateView<User?>(
                state: state,
                onRetry: context.read<UserDetailCubit>().retry,
                emptyIcon: Icons.person_off_outlined,
                emptyText: 'Пользователь не найден',
                builder: (_) => const SizedBox.shrink(),
              ),
            );
          }
          final u = state.data!;
          final users = context.read<UsersCubit>();
          return GradientScaffold(
            title: u.name,
            subtitle: u.email,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Редактировать',
                onPressed: () => showUserForm(context, cubit: users, user: u),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Удалить',
                onPressed: () async {
                  final nav = Navigator.of(context);
                  final current = getIt<CurrentUserCubit>();
                  if (!await confirm(
                    context,
                    'Удалить ${u.name}?',
                    'Пользователь будет исключён из всех проектов.',
                  )) {
                    return;
                  }
                  if (!context.mounted) return;
                  final ok = await runGuarded(
                    context,
                    () => users.delete(u.id),
                    success: 'Пользователь удалён',
                  );
                  if (ok) {
                    if (current.state == u.id) await current.select(null);
                    nav.pop();
                  }
                },
              ),
            ],
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          UserAvatar(name: u.name, id: u.id, size: 56),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Зарегистрирован ${fmtDate(u.registeredAt)}',
                                  style: const TextStyle(color: Tf.muted),
                                ),
                                const SizedBox(height: 8),
                                BlocBuilder<
                                  StreamCubit<List<Project>>,
                                  ViewState<List<Project>>
                                >(
                                  builder: (_, s) {
                                    final projects =
                                        s is ViewLoaded<List<Project>>
                                        ? s.data
                                        : <Project>[];
                                    if (projects.isEmpty) {
                                      return const Text(
                                        'Не состоит в проектах',
                                        style: TextStyle(fontSize: 13),
                                      );
                                    }
                                    return Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        for (final p in projects.take(6))
                                          Pill(label: p.name, color: Tf.accent),
                                        if (projects.length > 6)
                                          Pill(
                                            label: '+${projects.length - 6}',
                                            color: Tf.primary,
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SectionTitle('Задачи пользователя'),
                ),
                const Expanded(
                  child: TaskListView(emptyText: 'Задачи не назначены'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
