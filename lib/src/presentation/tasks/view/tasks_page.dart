import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/components/common.dart';
import 'package:lab11/core/di/injection.dart';
import 'package:lab11/src/presentation/tasks/bloc/task_list_cubit.dart';
import 'package:lab11/src/presentation/tasks/view/task_form_page.dart';
import 'package:lab11/src/presentation/tasks/widgets/task_list_view.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key, required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TaskListCubit>(),
      child: GradientScaffold(
        title: 'Задачи',
        subtitle: 'Все проекты',
        actions: actions,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'tasks-fab',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TaskFormPage()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Задача'),
        ),
        body: const TaskListView(),
      ),
    );
  }
}
