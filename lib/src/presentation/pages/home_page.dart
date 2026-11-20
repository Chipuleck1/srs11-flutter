import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../components/common.dart';
import '../../../constants/app_theme.dart';
import '../../../core/di/injection.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/user_usecases.dart';
import '../bloc/cubits.dart';
import '../bloc/view_state.dart';
import '../widgets/user_picker.dart';
import '../widgets/view_state_view.dart';
import 'dashboard_page.dart';
import 'import_page.dart';
import 'performance_page.dart';
import 'projects_page.dart';
import 'tasks_page.dart';
import 'trash_page.dart';
import 'users_page.dart';

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

/// Первый запуск: база пустая.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<WelcomeCubit>()),
        BlocProvider(create: (_) => getIt<UsersCubit>()),
      ],
      child: BlocBuilder<WelcomeCubit, bool>(
        builder: (context, loading) {
          final welcome = context.read<WelcomeCubit>();
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(gradient: Tf.gradient),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 92,
                          height: 92,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Tf.background,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: Tf.glow(0.6),
                          ),
                          child: const Icon(
                            Icons.task_alt_rounded,
                            size: 56,
                            color: Tf.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'TaskFlow',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Проекты, задачи и команда — всё работает офлайн и хранится в SQLite.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.4,
                        ),
                      ),
                      const Spacer(flex: 2),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Tf.background,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: loading
                            ? null
                            : () async {
                                final id = await showUserForm(
                                  context,
                                  cubit: context.read<UsersCubit>(),
                                );
                                if (id != null) {
                                  await getIt<CurrentUserCubit>().select(id);
                                }
                              },
                        icon: const Icon(Icons.person_add_alt),
                        label: const Text('Создать пользователя'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          minimumSize: const Size(0, 50),
                        ),
                        onPressed: loading
                            ? null
                            : () => runGuarded(context, welcome.seedDemo),
                        icon: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: const Text('Заполнить демо-данными'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
