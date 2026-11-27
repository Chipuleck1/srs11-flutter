import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/components/common.dart';
import 'package:lab11/components/view_state_view.dart';
import 'package:lab11/constants/app_theme.dart';
import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/di/injection.dart';
import 'package:lab11/src/presentation/pages/dashboard/dashboard_page.dart';
import 'package:lab11/src/presentation/bloc/home/current_user_cubit.dart';
import 'package:lab11/src/presentation/pages/home/welcome_page.dart';
import 'package:lab11/src/presentation/pages/performance/performance_page.dart';
import 'package:lab11/src/presentation/pages/projects/projects_page.dart';
import 'package:lab11/src/presentation/pages/server_import/import_page.dart';
import 'package:lab11/src/presentation/pages/tasks/tasks_page.dart';
import 'package:lab11/src/presentation/pages/trash/trash_page.dart';
import 'package:lab11/src/domain/entities/users/user.dart';
import 'package:lab11/src/domain/usecases/users/user_usecases.dart';
import 'package:lab11/src/presentation/pages/users/users_page.dart';
import 'package:lab11/src/presentation/widgets/users/user_picker.dart';

/// Главный экран: если пользователей нет — приветствие, иначе нижняя навигация.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StreamCubit<List<User>>(
        () => getIt<WatchUsersUseCase>()((search: '', limit: 1)),
      ),
      child: BlocBuilder<StreamCubit<List<User>>, ViewState<List<User>>>(
        builder: (context, state) => switch (state) {
          ViewEmpty() => const WelcomePage(),
          ViewLoaded(:final data) => _Shell(firstUserId: data.first.id),
          ViewError(:final message) => Scaffold(
            body: ErrorView(
              message: message,
              onRetry: context.read<StreamCubit<List<User>>>().retry,
            ),
          ),
          _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
        },
      ),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell({required this.firstUserId});

  final int firstUserId;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // Если текущий пользователь не выбран — берём первого
    final current = getIt<CurrentUserCubit>();
    if (current.state == null) current.select(widget.firstUserId);
  }

  @override
  Widget build(BuildContext context) {
    const actions = [_CurrentUserButton(), _MenuButton()];
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          DashboardPage(actions: actions),
          ProjectsPage(actions: actions),
          TasksPage(actions: actions),
          UsersPage(actions: actions),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Обзор',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Проекты',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Задачи',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Люди',
          ),
        ],
      ),
    );
  }
}

/// Аватар текущего пользователя в шапке — нажатие меняет пользователя.
class _CurrentUserButton extends StatelessWidget {
  const _CurrentUserButton();

  @override
  Widget build(BuildContext context) {
    final current = context.read<CurrentUserCubit>();
    return BlocBuilder<CurrentUserCubit, int?>(
      builder: (context, id) => BlocProvider(
        key: ValueKey(id),
        create: (_) =>
            StreamCubit<User?>(() => getIt<WatchUserUseCase>()(id ?? -1)),
        child: BlocBuilder<StreamCubit<User?>, ViewState<User?>>(
          builder: (context, state) {
            final u = state is ViewLoaded<User?> ? state.data : null;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () async {
                  final r = await pickUser(
                    context,
                    title: 'Кто работает с приложением?',
                  );
                  if (r?.user != null) await current.select(r!.user!.id);
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: u == null
                      ? const CircleAvatar(
                          radius: 16,
                          child: Icon(Icons.person, size: 18),
                        )
                      : Tooltip(
                          message: 'Вы: ${u.name}',
                          child: UserAvatar(name: u.name, id: u.id, size: 32),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert),
      onSelected: (v) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => switch (v) {
            0 => const ImportPage(),
            1 => const TrashPage(),
            _ => const PerformancePage(),
          },
        ),
      ),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 0,
          child: ListTile(
            leading: Icon(Icons.cloud_download_outlined, color: Tf.accent),
            title: Text('Импорт с сервера'),
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: Tf.accent),
            title: Text('Корзина'),
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: ListTile(
            leading: Icon(Icons.speed, color: Tf.accent),
            title: Text('Производительность'),
          ),
        ),
      ],
    );
  }
}
