import 'package:drift/drift.dart';

import 'dart:math';

import 'package:lab11/core/database/app_database.dart';
import 'package:lab11/models/enums.dart';

/// Демо-данные для первого запуска (кнопка на приветственном экране).
class DemoSeedLocalDataSource {
  DemoSeedLocalDataSource(this._db);

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
}
