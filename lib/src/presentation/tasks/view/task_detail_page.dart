import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/components/common.dart';
import 'package:lab11/components/view_state_view.dart';
import 'package:lab11/constants/app_theme.dart';
import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/di/injection.dart';
import 'package:lab11/models/enums.dart';
import 'package:lab11/src/presentation/home/bloc/current_user_cubit.dart';
import 'package:lab11/src/domain/tasks/entities/comment.dart';
import 'package:lab11/src/domain/tasks/entities/task.dart';
import 'package:lab11/src/domain/tasks/usecases/task_usecases.dart';
import 'package:lab11/src/presentation/tasks/bloc/comments_cubit.dart';
import 'package:lab11/src/presentation/tasks/bloc/task_detail_cubit.dart';
import 'package:lab11/src/presentation/tasks/view/task_form_page.dart';
import 'package:lab11/src/presentation/users/widgets/user_picker.dart';

class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({super.key, required this.taskId});

  final int taskId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<TaskDetailCubit>(param1: taskId)),
        BlocProvider(create: (_) => getIt<CommentsCubit>(param1: taskId)),
        BlocProvider(create: (_) => getIt<AttachmentsCubit>(param1: taskId)),
        BlocProvider(
          create: (_) => StreamCubit<List<HistoryEntry>>(
            () => getIt<WatchTaskHistoryUseCase>()(taskId),
          ),
        ),
      ],
      child: BlocBuilder<TaskDetailCubit, ViewState<TaskDetails?>>(
        builder: (context, state) {
          final cubit = context.read<TaskDetailCubit>();
          if (state is! ViewLoaded<TaskDetails?>) {
            return GradientScaffold(
              title: 'Задача',
              body: ViewStateView<TaskDetails?>(
                state: state,
                onRetry: cubit.retry,
                emptyIcon: Icons.delete_outline,
                emptyText: 'Задача удалена или не найдена',
                builder: (_) => const SizedBox.shrink(),
              ),
            );
          }
          final item = state.data!;
          return DefaultTabController(
            length: 3,
            child: GradientScaffold(
              title: item.task.title,
              subtitle: item.projectName,
              actions: [
                IconButton(
                  tooltip: 'Редактировать',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskFormPage(task: item.task),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'В корзину',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    final ok = await runGuarded(
                      context,
                      cubit.moveToTrash,
                      success: 'Задача перемещена в корзину',
                    );
                    if (ok) nav.pop();
                  },
                ),
              ],
              body: NestedScrollView(
                headerSliverBuilder: (_, _) => [
                  SliverToBoxAdapter(child: _TaskHeader(item: item)),
                  const SliverToBoxAdapter(
                    child: TabBar(
                      tabs: [
                        Tab(text: 'Комментарии'),
                        Tab(text: 'Вложения'),
                        Tab(text: 'История'),
                      ],
                    ),
                  ),
                ],
                body: const TabBarView(
                  children: [_CommentsTab(), _AttachmentsTab(), _HistoryTab()],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TaskHeader extends StatelessWidget {
  const _TaskHeader({required this.item});

  final TaskDetails item;

  Future<void> _changeStatus(BuildContext context, TaskStatus status) async {
    final cubit = context.read<TaskDetailCubit>();
    final actor = getIt<CurrentUserCubit>().state;
    final messenger = ScaffoldMessenger.of(context);
    final from = item.task.status;
    final ok = await runGuarded(
      context,
      () => cubit.changeStatus(status, actor),
    );
    if (!ok || from == status) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Статус: ${from.label} → ${status.label}'),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () => cubit.undo(actor),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = item.task;
    final cubit = context.read<TaskDetailCubit>();
    final actor = getIt<CurrentUserCubit>().state;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (t.description.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  t.description,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Статус',
            style: TextStyle(color: Tf.muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in TaskStatus.values)
                ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  labelPadding: const EdgeInsets.only(left: 2, right: 4),
                  avatar: Icon(
                    Tf.statusIcon(s),
                    size: 16,
                    color: s == t.status ? Colors.white : Tf.statusColor(s),
                  ),
                  label: Text(s.label),
                  selected: s == t.status,
                  showCheckmark: false,
                  selectedColor: Tf.statusColor(s),
                  backgroundColor: Tf.surfaceHigh,
                  side: BorderSide(
                    color: s == t.status ? Colors.transparent : Tf.border,
                  ),
                  labelStyle: TextStyle(
                    color: s == t.status ? Colors.white : Tf.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  onSelected: (_) => _changeStatus(context, s),
                ),
            ],
          ),
          FutureBuilder<bool>(
            key: ValueKey(
              t.updatedAt,
            ), // пересчёт после каждого изменения задачи
            future: cubit.canUndo(),
            builder: (context, snap) => snap.data == true
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Tf.accent),
                      onPressed: () => runGuarded(
                        context,
                        () => cubit.undo(actor),
                        success: 'Последнее изменение статуса отменено',
                      ),
                      icon: const Icon(Icons.undo),
                      label: const Text('Отменить последнее изменение статуса'),
                    ),
                  )
                : const SizedBox(height: 8),
          ),
          Card(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Приоритет',
                  child: PriorityPill(
                    t.priority,
                    onTap: () async {
                      final p = await pickOption<TaskPriority>(
                        context,
                        title: 'Приоритет',
                        options: TaskPriority.values,
                        label: (p) => p.label,
                        selected: t.priority,
                        leading: (p) => Icon(
                          Icons.circle,
                          size: 14,
                          color: Tf.priorityColor(p),
                        ),
                      );
                      if (p != null && context.mounted) {
                        await runGuarded(
                          context,
                          () => cubit.changePriority(p),
                        );
                      }
                    },
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Исполнитель',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      final r = await pickUser(
                        context,
                        title: 'Назначить исполнителя',
                        projectId: t.projectId,
                        noneLabel: 'Снять исполнителя',
                      );
                      if (r != null && context.mounted) {
                        await runGuarded(
                          context,
                          () => cubit.reassign(r.user?.id, actor),
                          success: 'Исполнитель изменён',
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.assignee != null) ...[
                          UserAvatar(
                            name: item.assignee!.name,
                            id: item.assignee!.id,
                            size: 26,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          item.assignee?.name ?? 'Не назначен',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Tf.accent,
                          ),
                        ),
                        const Icon(
                          Icons.expand_more,
                          size: 18,
                          color: Tf.accent,
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                _InfoRow(
                  icon: Icons.event,
                  label: 'Дедлайн',
                  child: Text(
                    fmtDate(t.deadline),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: t.isOverdue ? Tf.accent : Tf.ink,
                    ),
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                _InfoRow(
                  icon: Icons.add_circle_outline,
                  label: 'Создана',
                  child: Text(fmtDateTime(t.createdAt)),
                ),
                const Divider(indent: 16, endIndent: 16),
                _InfoRow(
                  icon: Icons.update,
                  label: 'Изменена',
                  child: Text(fmtDateTime(t.updatedAt)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Tf.primary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Tf.muted)),
          const Spacer(),
          child,
        ],
      ),
    );
  }
}

// ---------------- Комментарии ----------------

class _CommentsTab extends StatefulWidget {
  const _CommentsTab();

  @override
  State<_CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<_CommentsTab> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send(CommentsCubit cubit) async {
    final ok = await runGuarded(
      context,
      () => cubit.add(getIt<CurrentUserCubit>().state, _text.text),
    );
    if (ok) _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CommentsCubit>();
    final me = getIt<CurrentUserCubit>().state;
    return Column(
      children: [
        Expanded(
          child: BlocBuilder<CommentsCubit, ViewState<List<Comment>>>(
            builder: (context, state) => ViewStateView<List<Comment>>(
              state: state,
              onRetry: cubit.retry,
              emptyIcon: Icons.chat_bubble_outline,
              emptyText: 'Комментариев пока нет',
              builder: (list) => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final c = list[i];
                  final mine = c.author.id == me;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserAvatar(
                        name: c.author.name,
                        id: c.author.id,
                        size: 34,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
                          decoration: BoxDecoration(
                            color: mine ? Tf.accentSoft : Tf.surfaceHigh,
                            border: Border.all(
                              color: mine ? Colors.transparent : Tf.border,
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(18),
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.author.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    fmtDateTime(c.createdAt),
                                    style: const TextStyle(
                                      color: Tf.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (mine)
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      tooltip: 'Удалить',
                                      icon: const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Tf.accent,
                                      ),
                                      onPressed: () => runGuarded(
                                        context,
                                        () => cubit.delete(c.id, me),
                                      ),
                                    ),
                                ],
                              ),
                              Text(c.body),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: const BoxDecoration(
              color: Tf.surface,
              border: Border(top: BorderSide(color: Tf.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Написать комментарий…',
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Tf.primary),
                  onPressed: () => _send(cubit),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- Вложения ----------------

class _AttachmentsTab extends StatelessWidget {
  const _AttachmentsTab();

  Future<void> _add(BuildContext context, AttachmentsCubit cubit) async {
    final file = await FilePicker.pickFile();
    if (file == null || !context.mounted) return;
    // В базе сохраняется только путь к файлу
    await runGuarded(
      context,
      () => cubit.add(file.name, file.path ?? file.name),
      success: 'Файл прикреплён',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AttachmentsCubit>();
    final addButton = OutlinedButton.icon(
      onPressed: () => _add(context, cubit),
      icon: const Icon(Icons.attach_file),
      label: const Text('Прикрепить файл'),
    );
    return BlocBuilder<AttachmentsCubit, ViewState<List<Attachment>>>(
      builder: (context, state) {
        if (state is! ViewLoaded<List<Attachment>>) {
          return ViewStateView<List<Attachment>>(
            state: state,
            onRetry: cubit.retry,
            emptyIcon: Icons.attach_file,
            emptyText: 'Вложений нет',
            emptyAction: addButton,
            builder: (_) => const SizedBox.shrink(),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            addButton,
            const SizedBox(height: 12),
            for (final a in state.data)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Tf.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.insert_drive_file_outlined,
                        color: Tf.accent,
                      ),
                    ),
                    title: Text(
                      a.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${fmtDateTime(a.addedAt)}\n${a.filePath}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Tf.accent),
                      onPressed: () =>
                          runGuarded(context, () => cubit.delete(a.id)),
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

// ---------------- История ----------------

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StreamCubit<List<HistoryEntry>>>();
    return BlocBuilder<
      StreamCubit<List<HistoryEntry>>,
      ViewState<List<HistoryEntry>>
    >(
      builder: (context, state) => ViewStateView<List<HistoryEntry>>(
        state: state,
        onRetry: cubit.retry,
        emptyIcon: Icons.history,
        emptyText: 'История пуста',
        builder: (list) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final h = list[i];
            final color = switch (h.event) {
              HistoryEvent.created => Tf.primary,
              HistoryEvent.statusChanged => Tf.statusColor(h.newStatus),
              HistoryEvent.assigneeChanged => Tf.orange,
              HistoryEvent.undo => Tf.accent,
            };
            final text = switch (h.event) {
              HistoryEvent.created =>
                'Создана со статусом «${h.newStatus.label}»',
              HistoryEvent.statusChanged =>
                '${h.oldStatus?.label ?? '—'} → ${h.newStatus.label}',
              HistoryEvent.assigneeChanged => h.details ?? '',
              HistoryEvent.undo =>
                '${h.oldStatus?.label ?? '—'} → ${h.newStatus.label}',
            };
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Tf.background, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      if (i != list.length - 1)
                        Expanded(child: Container(width: 2, color: Tf.border)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                h.event.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                              if (h.reverted) ...[
                                const SizedBox(width: 6),
                                const Pill(label: 'отменено', color: Tf.muted),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(text),
                          if (h.event == HistoryEvent.undo && h.details != null)
                            Text(
                              h.details!,
                              style: const TextStyle(
                                color: Tf.muted,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            '${h.changedBy?.name ?? 'Система'} · ${fmtDateTime(h.changedAt)}',
                            style: const TextStyle(
                              color: Tf.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
