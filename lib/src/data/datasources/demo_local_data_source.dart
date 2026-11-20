import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../domain/entities/entities.dart';

/// Генерация тестовых данных и сравнение скорости запросов с индексами и без.
class DemoLocalDataSource {
  DemoLocalDataSource(this._db);

  final AppDatabase _db;

  static const _words = [
    'Дизайн',
    'Отчёт',
    'API',
    'Тесты',
    'Релиз',
    'Баг',
    'Экран',
    'База',
    'Анализ',
    'Встреча',
    'Документация',
    'Оптимизация',
    'Логин',
    'Оплата',
  ];

  /// Небольшой набор данных для первого знакомства с приложением.
  Future<void> seedDemo() => _db.transaction(() async {
    final now = DateTime.now();
    final names = ['Наталья', 'Алексей', 'Мария', 'Дмитрий', 'Айгерим'];
    final emails = ['natali', 'alex', 'maria', 'dima', 'aigerim'];
    final userIds = <int>[];
    for (var i = 0; i < names.length; i++) {
      userIds.add(
        await _db
            .into(_db.users)
            .insert(
              UsersCompanion.insert(
                name: names[i],
                email: '${emails[i]}@taskflow.app',
                registeredAt: now.subtract(Duration(days: 30 - i * 5)),
              ),
            ),
      );
    }
    final projects = [
      ('Мобильное приложение', 'Разработка Flutter-приложения TaskFlow'),
      ('Сайт компании', 'Редизайн и новая главная страница'),
      ('Маркетинг', 'Запуск рекламной кампании'),
    ];
    final rnd = Random(7);
    for (var p = 0; p < projects.length; p++) {
      final pid = await _db
          .into(_db.projects)
          .insert(
            ProjectsCompanion.insert(
              name: projects[p].$1,
              description: Value(projects[p].$2),
              createdAt: now.subtract(Duration(days: 20 - p * 3)),
              status: p == 2 ? ProjectStatus.completed : ProjectStatus.active,
            ),
          );
      final members = userIds.skip(p).take(3).toList();
      for (var m = 0; m < members.length; m++) {
        await _db
            .into(_db.projectMembers)
            .insert(
              ProjectMembersCompanion.insert(
                projectId: pid,
                userId: members[m],
                role: m == 0
                    ? MemberRole.owner
                    : (m == 1 ? MemberRole.admin : MemberRole.member),
                joinedAt: now,
              ),
            );
      }
      for (var t = 0; t < 6; t++) {
        final status = TaskStatus.values[rnd.nextInt(TaskStatus.values.length)];
        final created = now.subtract(Duration(days: rnd.nextInt(15), hours: t));
        final tid = await _db
            .into(_db.tasks)
            .insert(
              TasksCompanion.insert(
                title:
                    '${_words[(p * 6 + t) % _words.length]}: задача ${t + 1}',
                description: Value(
                  'Описание задачи ${t + 1} проекта «${projects[p].$1}»',
                ),
                projectId: pid,
                assigneeId: Value(members[t % members.length]),
                priority: Value(TaskPriority.values[rnd.nextInt(4)]),
                status: status,
                deadline: Value(now.add(Duration(days: rnd.nextInt(20) - 5))),
                createdAt: created,
                updatedAt: created,
              ),
            );
        await _db
            .into(_db.taskHistory)
            .insert(
              TaskHistoryCompanion.insert(
                taskId: tid,
                event: HistoryEvent.created,
                newStatus: status,
                changedBy: Value(members.first),
                changedAt: created,
              ),
            );
      }
    }
  });

  /// Большая база: 1 000 пользователей, 100 проектов, 10 000 задач.
  Future<void> seedLarge({
    int users = 1000,
    int projects = 100,
    int tasks = 10000,
    void Function(String step)? onProgress,
  }) => _db.transaction(() async {
    final rnd = Random(42);
    final now = DateTime.now();
    final stamp = now.millisecondsSinceEpoch;

    onProgress?.call('Пользователи…');
    await _db.batch((b) {
      b.insertAll(_db.users, [
        for (var i = 0; i < users; i++)
          UsersCompanion.insert(
            name: 'User ${i + 1}',
            email: 'user${i + 1}.$stamp@test.local',
            registeredAt: now.subtract(Duration(days: rnd.nextInt(700))),
          ),
      ]);
    });

    final userIds = await _lastIds('users', users);

    onProgress?.call('Проекты и участники…');
    await _db.batch((b) {
      b.insertAll(_db.projects, [
        for (var i = 0; i < projects; i++)
          ProjectsCompanion.insert(
            name: 'Проект ${i + 1}',
            description: Value('Тестовый проект №${i + 1}'),
            createdAt: now.subtract(Duration(days: rnd.nextInt(365))),
            status: ProjectStatus.values[rnd.nextInt(3)],
          ),
      ]);
    });
    final projectIds = await _lastIds('projects', projects);
    const membersPerProject = 10;
    await _db.batch((b) {
      for (var p = 0; p < projects; p++) {
        for (var m = 0; m < membersPerProject; m++) {
          b.insert(
            _db.projectMembers,
            ProjectMembersCompanion.insert(
              projectId: projectIds[p],
              userId: userIds[(p * membersPerProject + m) % users],
              role: m == 0 ? MemberRole.owner : MemberRole.member,
              joinedAt: now,
            ),
          );
        }
      }
    });

    onProgress?.call('Задачи…');
    await _db.batch((b) {
      b.insertAll(_db.tasks, [
        for (var i = 0; i < tasks; i++)
          () {
            final p = i % projects;
            final created = now.subtract(
              Duration(minutes: rnd.nextInt(525600)),
            );
            return TasksCompanion.insert(
              title: '${_words[rnd.nextInt(_words.length)]} #${i + 1}',
              description: Value('Сгенерированная задача ${i + 1}'),
              projectId: projectIds[p],
              assigneeId: Value(
                userIds[(p * membersPerProject +
                        rnd.nextInt(membersPerProject)) %
                    users],
              ),
              priority: Value(TaskPriority.values[rnd.nextInt(4)]),
              status: TaskStatus.values[rnd.nextInt(4)],
              deadline: Value(now.add(Duration(days: rnd.nextInt(365) - 60))),
              createdAt: created,
              updatedAt: created,
            );
          }(),
      ]);
    });
  });

  /// id только что вставленных [count] строк (по возрастанию).
  /// Внутри транзакции это всегда самые большие id таблицы — в отличие от
  /// MAX(id)+1, это верно и после удалений (AUTOINCREMENT не переиспользует id).
  Future<List<int>> _lastIds(String table, int count) async {
    final rows = await _db
        .customSelect('SELECT id FROM $table ORDER BY id DESC LIMIT $count')
        .get();
    return rows.map((r) => r.read<int>('id')).toList().reversed.toList();
  }

  Future<int> countTasks() async =>
      (await _db.customSelect('SELECT COUNT(*) AS c FROM tasks').getSingle())
          .read<int>('c');

  /// Каждый запрос выполняется [repeat] раз с индексами, затем индексы
  /// таблицы tasks удаляются, запросы повторяются, и индексы создаются заново.
  Future<List<BenchmarkResult>> runBenchmark({int repeat = 20}) async {
    final assignee =
        (await _db
                .customSelect(
                  'SELECT assignee_id AS a FROM tasks WHERE assignee_id IS NOT NULL LIMIT 1',
                )
                .getSingleOrNull())
            ?.read<int>('a') ??
        1;
    final project =
        (await _db
                .customSelect('SELECT MIN(id) AS p FROM projects')
                .getSingle())
            .read<int?>('p') ??
        1;

    final queries = <String, (String, List<Variable>)>{
      'Фильтр по исполнителю': (
        'SELECT * FROM tasks WHERE assignee_id = ? AND deleted_at IS NULL',
        [Variable.withInt(assignee)],
      ),
      'Задачи проекта': (
        'SELECT * FROM tasks WHERE project_id = ? AND deleted_at IS NULL',
        [Variable.withInt(project)],
      ),
      'Статус + сортировка по дедлайну (стр. 1)': (
        "SELECT * FROM tasks WHERE status = 'todo' ORDER BY deadline LIMIT 30",
        [],
      ),
      'Сортировка по дате создания (стр. 1)': (
        'SELECT * FROM tasks ORDER BY created_at DESC LIMIT 30',
        [],
      ),
      'Поиск по названию (префикс)': (
        "SELECT * FROM tasks WHERE title >= 'Релиз' AND title < 'Релиз~' LIMIT 30",
        [],
      ),
      'Поиск по подстроке LIKE %…%': (
        "SELECT * FROM tasks WHERE title LIKE '%99%' OR description LIKE '%99%'",
        [],
      ),
    };

    Future<Map<String, double>> measure() async {
      final out = <String, double>{};
      for (final e in queries.entries) {
        await _db
            .customSelect(e.value.$1, variables: e.value.$2)
            .get(); // прогрев
        final sw = Stopwatch()..start();
        for (var i = 0; i < repeat; i++) {
          await _db.customSelect(e.value.$1, variables: e.value.$2).get();
        }
        sw.stop();
        out[e.key] = sw.elapsedMicroseconds / 1000 / repeat;
      }
      return out;
    }

    final withIdx = await measure();
    for (final idx in _db.taskIndexes) {
      await _db.customStatement('DROP INDEX IF EXISTS ${idx.entityName}');
    }
    final withoutIdx = await measure();
    for (final idx in _db.taskIndexes) {
      await _db.customStatement(
        idx.createStatementsByDialect[SqlDialect.sqlite]!,
      );
    }

    return [
      for (final name in queries.keys)
        BenchmarkResult(name, withIdx[name]!, withoutIdx[name]!),
    ];
  }

  /// Удалить все данные (каскадно удалятся связанные записи).
  Future<void> clearAll() => _db.transaction(() async {
    await _db.delete(_db.projects).go();
    await _db.delete(_db.users).go();
  });
}
