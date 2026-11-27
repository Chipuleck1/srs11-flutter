import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/components/common.dart';
import 'package:lab11/components/view_state_view.dart';
import 'package:lab11/constants/app_theme.dart';
import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/di/injection.dart';
import 'package:lab11/models/enums.dart';
import 'package:lab11/src/domain/entities/projects/project.dart';
import 'package:lab11/src/presentation/bloc/projects/members_cubit.dart';
import 'package:lab11/src/presentation/bloc/projects/project_detail_cubit.dart';
import 'package:lab11/src/presentation/bloc/projects/projects_cubit.dart';
import 'package:lab11/src/presentation/pages/projects/projects_page.dart';
import 'package:lab11/src/presentation/bloc/tasks/task_list_cubit.dart';
import 'package:lab11/src/presentation/pages/tasks/task_form_page.dart';
import 'package:lab11/src/presentation/widgets/tasks/task_list_view.dart';
import 'package:lab11/src/presentation/pages/users/user_detail_page.dart';
import 'package:lab11/src/presentation/widgets/users/user_picker.dart';

class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<ProjectDetailCubit>(param1: projectId),
        ),
        BlocProvider(create: (_) => getIt<ProjectsCubit>()),
        BlocProvider(create: (_) => getIt<MembersCubit>(param1: projectId)),
        BlocProvider(create: (_) => getIt<TaskListCubit>(param1: projectId)),
      ],
      child: BlocBuilder<ProjectDetailCubit, ViewState<Project?>>(
        builder: (context, state) {
          if (state is! ViewLoaded<Project?>) {
            return GradientScaffold(
              title: 'Проект',
              body: ViewStateView<Project?>(
                state: state,
                onRetry: context.read<ProjectDetailCubit>().retry,
                emptyIcon: Icons.folder_off_outlined,
                emptyText: 'Проект не найден',
                builder: (_) => const SizedBox.shrink(),
              ),
            );
          }
          final p = state.data!;
          final projects = context.read<ProjectsCubit>();
          return DefaultTabController(
            length: 2,
            child: GradientScaffold(
              title: p.name,
              subtitle:
                  '${p.status.label} · с ${fmtDate(p.createdAt)}'
                  '${p.endDate != null ? ' до ${fmtDate(p.endDate)}' : ''}',
              actions: [
                IconButton(
                  tooltip: 'Редактировать',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      showProjectForm(context, cubit: projects, project: p),
                ),
                IconButton(
                  tooltip: 'Удалить проект',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    if (await confirm(
                          context,
                          'Удалить проект?',
                          'Вместе с проектом будут удалены все его задачи, комментарии и участники.',
                        ) &&
                        context.mounted) {
                      final ok = await runGuarded(
                        context,
                        () => projects.delete(p.id),
                      );
                      if (ok) nav.pop();
                    }
                  },
                ),
              ],
              bottom: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Задачи'),
                  Tab(text: 'Участники'),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                heroTag: 'project-fab',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskFormPage(projectId: projectId),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Задача'),
              ),
              body: const TabBarView(
                children: [
                  TaskListView(
                    showProject: false,
                    emptyText: 'В проекте пока нет задач',
                  ),
                  _MembersTab(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  const _MembersTab();

  Future<void> _add(BuildContext context, MembersCubit cubit) async {
    final r = await pickUser(
      context,
      title: 'Добавить участника',
      excludeProjectId: cubit.projectId,
    );
    if (r?.user == null || !context.mounted) return;
    final role = await pickOption<MemberRole>(
      context,
      title: 'Роль для ${r!.user!.name}',
      options: MemberRole.values,
      label: (r) => r.label,
      selected: MemberRole.member,
    );
    if (role == null || !context.mounted) return;
    await runGuarded(
      context,
      () => cubit.add(r.user!.id, role),
      success: 'Участник добавлен',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MembersCubit>();
    return BlocBuilder<MembersCubit, ViewState<List<ProjectMember>>>(
      builder: (context, state) {
        final addButton = OutlinedButton.icon(
          onPressed: () => _add(context, cubit),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Добавить участника'),
        );
        if (state is! ViewLoaded<List<ProjectMember>>) {
          return ViewStateView<List<ProjectMember>>(
            state: state,
            onRetry: cubit.retry,
            emptyIcon: Icons.group_outlined,
            emptyText: 'Участников пока нет',
            emptyAction: addButton,
            builder: (_) => const SizedBox.shrink(),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            addButton,
            const SizedBox(height: 12),
            for (final m in state.data)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserDetailPage(userId: m.user.id),
                      ),
                    ),
                    leading: UserAvatar(
                      name: m.user.name,
                      id: m.user.id,
                      size: 40,
                    ),
                    title: Text(
                      m.user.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(m.user.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Pill(
                          label: m.role.label,
                          color: switch (m.role) {
                            MemberRole.owner => Tf.primary,
                            MemberRole.admin => Tf.accent,
                            MemberRole.member => Tf.muted,
                          },
                          onTap: () async {
                            final role = await pickOption<MemberRole>(
                              context,
                              title: 'Роль',
                              options: MemberRole.values,
                              label: (r) => r.label,
                              selected: m.role,
                            );
                            if (role != null && context.mounted) {
                              await runGuarded(
                                context,
                                () => cubit.changeRole(m.user.id, role),
                              );
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Исключить',
                          icon: const Icon(
                            Icons.person_remove_outlined,
                            color: Tf.accent,
                          ),
                          onPressed: () async {
                            if (await confirm(
                                  context,
                                  'Исключить ${m.user.name}?',
                                  'С задач этого участника в проекте будет снято назначение.',
                                  ok: 'Исключить',
                                ) &&
                                context.mounted) {
                              await runGuarded(
                                context,
                                () => cubit.remove(m.user.id),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
