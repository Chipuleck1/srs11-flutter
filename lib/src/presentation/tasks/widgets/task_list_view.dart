import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/components/common.dart';
import 'package:lab11/components/view_state_view.dart';
import 'package:lab11/constants/app_theme.dart';
import 'package:lab11/models/enums.dart';
import 'package:lab11/src/domain/tasks/entities/task.dart';
import 'package:lab11/src/presentation/tasks/bloc/task_list_cubit.dart';
import 'package:lab11/src/presentation/tasks/view/task_detail_page.dart';
import 'package:lab11/src/presentation/tasks/widgets/task_card.dart';
import 'package:lab11/src/presentation/users/widgets/user_picker.dart';

class _Choice<T> {
  const _Choice(this.value);
  final T? value;
}

/// Список задач с поиском, фильтрами, сортировкой и бесконечной прокруткой.
/// Ожидает [TaskListCubit] выше по дереву (BlocProvider).
class TaskListView extends StatefulWidget {
  const TaskListView({
    super.key,
    this.showProject = true,
    this.emptyText = 'Задач пока нет',
  });

  final bool showProject;
  final String emptyText;

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clear(TaskListCubit c) {
    _search.clear();
    c.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.read<TaskListCubit>();
    return BlocBuilder<TaskListCubit, TaskListState>(
      builder: (context, state) => Column(
        children: [
          _FilterBar(cubit: c, state: state, searchController: _search),
          Expanded(
            child: ViewStateView<List<TaskDetails>>(
              state: state.items,
              onRetry: c.retry,
              emptyIcon: state.hasFilters ? Icons.search_off : Icons.task_alt,
              emptyText: state.hasFilters
                  ? 'Ничего не найдено'
                  : widget.emptyText,
              emptyAction: state.hasFilters
                  ? OutlinedButton(
                      onPressed: () => _clear(c),
                      child: const Text('Сбросить фильтры'),
                    )
                  : null,
              builder: (items) => NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.extentAfter < 300) c.loadMore(); // пагинация
                  return false;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (i == items.length) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: state.hasMore
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Это все задачи',
                                  style: TextStyle(color: Tf.muted),
                                ),
                        ),
                      );
                    }
                    final item = items[i];
                    return TaskCard(
                      item: item,
                      showProject: widget.showProject,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailPage(taskId: item.task.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.cubit,
    required this.state,
    required this.searchController,
  });

  final TaskListCubit cubit;
  final TaskListState state;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final f = state.filter;
    final controller = cubit;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            onChanged: controller.setSearch,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Tf.primary),
              hintText: 'Поиск по названию и описанию',
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        searchController.clear();
                        controller.setSearch('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  icon: Icons.flag_outlined,
                  label: f.status?.label ?? 'Статус',
                  active: f.status != null,
                  onTap: () async {
                    final r = await pickOption<_Choice<TaskStatus>>(
                      context,
                      title: 'Статус',
                      options: [
                        const _Choice(null),
                        ...TaskStatus.values.map(_Choice.new),
                      ],
                      label: (c) => c.value?.label ?? 'Все статусы',
                      leading: (c) => Icon(
                        c.value == null
                            ? Icons.all_inclusive
                            : Tf.statusIcon(c.value!),
                        color: c.value == null
                            ? Tf.muted
                            : Tf.statusColor(c.value!),
                      ),
                    );
                    if (r != null) controller.setStatus(r.value);
                  },
                ),
                _FilterChip(
                  icon: Icons.local_fire_department_outlined,
                  label: f.priority?.label ?? 'Приоритет',
                  active: f.priority != null,
                  onTap: () async {
                    final r = await pickOption<_Choice<TaskPriority>>(
                      context,
                      title: 'Приоритет',
                      options: [
                        const _Choice(null),
                        ...TaskPriority.values.map(_Choice.new),
                      ],
                      label: (c) => c.value?.label ?? 'Любой приоритет',
                      leading: (c) => Icon(
                        Icons.circle,
                        size: 14,
                        color: c.value == null
                            ? Tf.border
                            : Tf.priorityColor(c.value!),
                      ),
                    );
                    if (r != null) controller.setPriority(r.value);
                  },
                ),
                if (!state.fixedAssignee)
                  _FilterChip(
                    icon: Icons.person_outline,
                    label: f.assigneeId == null
                        ? 'Исполнитель'
                        : (state.assigneeName ?? 'Исполнитель'),
                    active: f.assigneeId != null,
                    onTap: () async {
                      final r = await pickUser(
                        context,
                        title: 'Исполнитель',
                        projectId: f.projectId,
                        noneLabel: 'Все исполнители',
                      );
                      if (r != null) {
                        controller.setAssignee(r.user?.id, r.user?.name);
                      }
                    },
                  ),
                _FilterChip(
                  icon: Icons.swap_vert,
                  label: f.sort.label,
                  active: false,
                  onTap: () async {
                    final r = await pickOption<TaskSort>(
                      context,
                      title: 'Сортировка',
                      options: TaskSort.values,
                      label: (s) => s.label,
                      selected: f.sort,
                    );
                    if (r != null) controller.setSort(r);
                  },
                ),
                if (state.hasFilters)
                  IconButton(
                    tooltip: 'Сбросить фильтры',
                    onPressed: () {
                      searchController.clear();
                      controller.clear();
                    },
                    icon: const Icon(
                      Icons.filter_alt_off_outlined,
                      color: Tf.accent,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              state.total != null ? 'Найдено задач: ${state.total}' : ' ',
              style: const TextStyle(color: Tf.muted, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : Tf.ink;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        shape: StadiumBorder(
          side: BorderSide(color: active ? Colors.transparent : Tf.border),
        ),
        color: Tf.surfaceHigh,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(gradient: active ? Tf.gradient : null),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: active ? Colors.white : Tf.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Icon(Icons.expand_more, size: 17, color: fg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
