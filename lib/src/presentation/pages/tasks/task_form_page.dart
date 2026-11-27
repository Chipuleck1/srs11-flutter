import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/components/common.dart';
import 'package:lab11/constants/app_theme.dart';
import 'package:lab11/core/di/injection.dart';
import 'package:lab11/core/validation/validators.dart';
import 'package:lab11/models/enums.dart';
import 'package:lab11/src/presentation/bloc/home/current_user_cubit.dart';
import 'package:lab11/src/domain/entities/tasks/task.dart';
import 'package:lab11/src/presentation/bloc/tasks/task_form_cubit.dart';

/// Создание новой задачи ([task] == null) или редактирование существующей.
class TaskFormPage extends StatelessWidget {
  const TaskFormPage({super.key, this.task, this.projectId});

  final Task? task;
  final int? projectId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TaskFormCubit>()..init(task?.projectId ?? projectId),
      child: _TaskForm(task: task, projectId: projectId),
    );
  }
}

class _TaskForm extends StatefulWidget {
  const _TaskForm({this.task, this.projectId});

  final Task? task;
  final int? projectId;

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.task?.title);
  late final _description = TextEditingController(
    text: widget.task?.description,
  );
  late int? _projectId = widget.task?.projectId ?? widget.projectId;
  late int? _assigneeId = widget.task?.assigneeId;
  late TaskPriority _priority = widget.task?.priority ?? TaskPriority.medium;
  late DateTime? _deadline = widget.task?.deadline;

  bool get _isEdit => widget.task != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (d != null) setState(() => _deadline = d);
  }

  Future<void> _save(TaskFormCubit cubit) async {
    if (!_form.currentState!.validate()) return;
    final nav = Navigator.of(context);
    final ok = await runGuarded(
      context,
      () => cubit.submit(
        existing: widget.task,
        actorId: getIt<CurrentUserCubit>().state,
        draft: TaskDraft(
          projectId: _projectId,
          title: _title.text,
          description: _description.text,
          assigneeId: _assigneeId,
          priority: _priority,
          deadline: _deadline,
        ),
      ),
      success: _isEdit ? 'Задача сохранена' : 'Задача создана',
    );
    if (ok && mounted) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskFormCubit>();
    return BlocBuilder<TaskFormCubit, TaskFormState>(
      builder: (context, state) {
        final members = state.members;
        final assignee = members.any((u) => u.id == _assigneeId)
            ? _assigneeId
            : null;
        return GradientScaffold(
          title: _isEdit ? 'Редактирование' : 'Новая задача',
          body: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: Validators.form(
                    (v) => Validators.text(v, 'Название', max: 200),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey('project-${state.projects.length}'),
                  initialValue: state.projects.any((p) => p.id == _projectId)
                      ? _projectId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Проект',
                    prefixIcon: Icon(Icons.folder_outlined),
                  ),
                  items: [
                    for (final p in state.projects)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: _isEdit || widget.projectId != null
                      ? null
                      : (v) {
                          setState(() {
                            _projectId = v;
                            _assigneeId = null;
                          });
                          cubit.loadMembers(v);
                        },
                  validator: (v) =>
                      v == null ? 'Задача должна принадлежать проекту' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  key: ValueKey('assignee-$_projectId-${members.length}'),
                  initialValue: assignee,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Исполнитель',
                    prefixIcon: const Icon(Icons.person_outline),
                    helperText: _projectId == null
                        ? 'Сначала выберите проект'
                        : 'Только участники проекта',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Не назначен'),
                    ),
                    for (final u in members)
                      DropdownMenuItem(value: u.id, child: Text(u.name)),
                  ],
                  onChanged: (v) => setState(() => _assigneeId = v),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Приоритет',
                  style: TextStyle(
                    color: Tf.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in TaskPriority.values)
                      ChoiceChip(
                        label: Text(p.label),
                        selected: _priority == p,
                        showCheckmark: false,
                        selectedColor: Tf.priorityColor(p),
                        backgroundColor: Tf.surfaceHigh,
                        side: BorderSide(
                          color: _priority == p
                              ? Colors.transparent
                              : Tf.border,
                        ),
                        labelStyle: TextStyle(
                          color: _priority == p ? Colors.white : Tf.ink,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => _priority = p),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.event, color: Tf.accent),
                    title: const Text('Дедлайн'),
                    subtitle: Text(
                      _deadline == null ? 'Не задан' : fmtDate(_deadline),
                    ),
                    trailing: _deadline == null
                        ? const Icon(Icons.chevron_right)
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _deadline = null),
                          ),
                    onTap: _pickDeadline,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  // кнопка заблокирована, пока идёт сохранение
                  onPressed: state.submitting ? null : () => _save(cubit),
                  icon: state.submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isEdit ? 'Сохранить' : 'Создать задачу'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
