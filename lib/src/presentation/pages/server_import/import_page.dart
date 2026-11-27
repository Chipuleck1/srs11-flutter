import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/components/common.dart';
import 'package:lab11/constants/app_theme.dart';
import 'package:lab11/core/di/injection.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/presentation/pages/projects/project_detail_page.dart';
import 'package:lab11/src/presentation/bloc/server_import/import_cubit.dart';

/// НОВАЯ ФУНКЦИЯ: импорт пользователей и задач с сервера (JSONPlaceholder).
/// Показывает все состояния: Initial, Loading, Success, Empty, Error + повтор запроса.
class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  int _count = 20;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ImportCubit>(),
      child: BlocBuilder<ImportCubit, ImportState>(
        builder: (context, state) {
          final cubit = context.read<ImportCubit>();
          final loading = state is ImportLoading;
          return GradientScaffold(
            title: 'Импорт с сервера',
            subtitle: 'jsonplaceholder.typicode.com',
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.cloud_download_outlined,
                              color: Tf.accent,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Что произойдёт',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Приложение загрузит 10 пользователей (GET /users) и задачи (GET /todos), '
                          'создаст новый проект и сохранит всё в локальную базу. '
                          'Пользователи с уже существующим email не дублируются.',
                          style: TextStyle(color: Tf.muted, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Сколько задач загрузить: $_count',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Slider(
                          value: _count.toDouble(),
                          min: 5,
                          max: 100,
                          divisions: 19,
                          label: '$_count',
                          onChanged: loading
                              ? null
                              : (v) => setState(() => _count = v.round()),
                        ),
                        FilledButton.icon(
                          // во время запроса кнопка заблокирована (нет повторных запросов)
                          onPressed: loading ? null : () => cubit.start(_count),
                          icon: loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.download),
                          label: Text(loading ? 'Загрузка…' : 'Загрузить'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                switch (state) {
                  ImportInitial() => const SizedBox.shrink(),
                  ImportLoading() => const _StatusCard(
                    icon: Icons.sync,
                    color: Tf.muted,
                    title: 'Загружаем данные с сервера…',
                    child: LinearProgressIndicator(),
                  ),
                  ImportSuccess(:final result) => _StatusCard(
                    icon: Icons.check_circle,
                    color: Tf.green,
                    title: 'Импорт завершён',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Проект: ${result.projectName}'),
                        Text('Новых пользователей: ${result.usersCreated}'),
                        Text('Уже были в базе: ${result.usersReused}'),
                        Text('Задач: ${result.tasksCreated}'),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailPage(
                                projectId: result.projectId!,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Открыть проект'),
                        ),
                      ],
                    ),
                  ),
                  ImportEmpty() => const _StatusCard(
                    icon: Icons.inbox_outlined,
                    color: Tf.muted,
                    title: 'Сервер не вернул данных',
                    child: Text(
                      'Импортировать нечего.',
                      style: TextStyle(color: Tf.muted),
                    ),
                  ),
                  ImportError(:final failure, :final canRetry) => _StatusCard(
                    icon: _errorIcon(failure),
                    color: Tf.accent,
                    title: failure.message,
                    child: canRetry
                        ? FilledButton.icon(
                            onPressed: cubit
                                .retry, // повторная отправка неудачного запроса
                            icon: const Icon(Icons.refresh),
                            label: const Text('Повторить'),
                          )
                        : const Text(
                            'Проверьте параметры запроса.',
                            style: TextStyle(color: Tf.muted),
                          ),
                  ),
                },
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _errorIcon(Failure f) => switch (f) {
    NetworkFailure() => Icons.wifi_off,
    ServerFailure() => Icons.dns_outlined,
    UnauthorizedFailure() => Icons.lock_outline,
    ValidationFailure() => Icons.rule,
    _ => Icons.error_outline,
  };
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
