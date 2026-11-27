import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/components/common.dart';
import 'package:lab11/components/view_state_view.dart';
import 'package:lab11/constants/app_theme.dart';
import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/di/injection.dart';
import 'package:lab11/core/validation/validators.dart';
import 'package:lab11/models/enums.dart';
import 'package:lab11/src/presentation/home/bloc/current_user_cubit.dart';
import 'package:lab11/src/domain/projects/entities/project.dart';
import 'package:lab11/src/presentation/projects/bloc/projects_cubit.dart';
import 'package:lab11/src/presentation/projects/view/project_detail_page.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key, required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProjectsCubit>(),
      child: Builder(
        builder: (context) {
          final cubit = context.read<ProjectsCubit>();
          return GradientScaffold(
            title: 'Проекты',
            actions: actions,
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'projects-fab',
              onPressed: () => showProjectForm(context, cubit: cubit),
              icon: const Icon(Icons.add),
              label: const Text('Проект'),
            ),
            body: BlocBuilder<ProjectsCubit, ViewState<List<ProjectSummary>>>(
              builder: (context, state) => ViewStateView<List<ProjectSummary>>(
                state: state,
                onRetry: cubit.retry,
                emptyIcon: Icons.folder_open,
                emptyText: 'Создайте первый проект',
                emptyAction: FilledButton(
                  onPressed: () => showProjectForm(context, cubit: cubit),
                  child: const Text('Новый проект'),
                ),
                builder: (list) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => ProjectCard(item: list[i]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.item});

  final ProjectSummary item;

  @override
  Widget build(BuildContext context) {
    final p = item.project;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: p.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: Tf.gradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Pill(
                          label: p.status.label,
                          color: Tf.projectStatusColor(p.status),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(item.progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Tf.accent,
                    ),
                  ),
                ],
              ),
              if (p.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  p.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Tf.muted),
                ),
              ],
              const SizedBox(height: 14),
              GradientProgress(value: item.progress),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.task_alt, size: 16, color: Tf.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${item.doneTasks}/${item.totalTasks} задач',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.group_outlined, size: 16, color: Tf.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${item.membersCount}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const Spacer(),
                  if (p.endDate != null) ...[
                    const Icon(Icons.flag_outlined, size: 16, color: Tf.muted),
                    const SizedBox(width: 4),
                    Text(
                      fmtDate(p.endDate),
                      style: const TextStyle(fontSize: 13, color: Tf.muted),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Создание или редактирование проекта.
Future<void> showProjectForm(
  BuildContext context, {
  required ProjectsCubit cubit,
  Project? project,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Tf.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _ProjectForm(cubit: cubit, project: project),
  );
}

class _ProjectForm extends StatefulWidget {
  const _ProjectForm({required this.cubit, this.project});

  final ProjectsCubit cubit;
  final Project? project;

  @override
  State<_ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<_ProjectForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.project?.name);
  late final _description = TextEditingController(
    text: widget.project?.description,
  );
  late ProjectStatus _status = widget.project?.status ?? ProjectStatus.active;
  late DateTime? _endDate = widget.project?.endDate;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    final p = widget.project;
    final data = (
      name: _name.text,
      description: _description.text,
      status: _status,
      endDate: _endDate,
    );
    final ok = await runGuarded(
      context,
      () => p == null
          ? widget.cubit.create(data, ownerId: getIt<CurrentUserCubit>().state)
          : widget.cubit.update(p.id, data),
      success: p == null ? 'Проект создан' : 'Проект сохранён',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.project == null
                  ? 'Новый проект'
                  : 'Редактирование проекта',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Название'),
              validator: Validators.form(
                (v) => Validators.text(v, 'Название', max: 100),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ProjectStatus>(
              segments: [
                for (final s in ProjectStatus.values)
                  ButtonSegment(value: s, label: Text(s.label)),
              ],
              selected: {_status},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _status = s.first),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.flag_outlined, color: Tf.accent),
              title: const Text('Дата завершения (необязательно)'),
              subtitle: Text(
                _endDate == null ? 'Не задана' : fmtDate(_endDate),
              ),
              trailing: _endDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _endDate = null),
                    ),
              onTap: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? now,
                  firstDate: DateTime(now.year - 2),
                  lastDate: DateTime(now.year + 5),
                );
                if (d != null) setState(() => _endDate = d);
              },
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
