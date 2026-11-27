import 'package:drift/drift.dart';

import 'package:lab11/core/database/app_database.dart';
import 'package:lab11/models/enums.dart';
import 'package:lab11/models/server_import/remote_models.dart';
import 'package:lab11/src/domain/server_import/entities/import_result.dart';

/// Сохраняет загруженные с сервера данные в SQLite одной транзакцией.
class ImportLocalDataSource {
  ImportLocalDataSource(this._db);

  final AppDatabase _db;

  Future<ImportResult> save(
    List<RemoteUserModel> users,
    List<RemoteTodoModel> todos,
  ) => _db.transaction(() async {
    final now = DateTime.now();
    final projectName =
        'Импорт ${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // 1. Пользователи: если email уже есть — используем существующего
    final idByRemote = <int, int>{};
    var created = 0, reused = 0;
    for (final u in users) {
      final email = u.email.trim().toLowerCase();
      final existing = await (_db.select(
        _db.users,
      )..where((x) => x.email.equals(email))).getSingleOrNull();
      if (existing != null) {
        idByRemote[u.id] = existing.id;
        reused++;
      } else {
        idByRemote[u.id] = await _db
            .into(_db.users)
            .insert(
              UsersCompanion.insert(
                name: u.name,
                email: email,
                registeredAt: now,
              ),
            );
        created++;
      }
    }

    // 2. Новый проект; участники — все импортированные пользователи
    final projectId = await _db
        .into(_db.projects)
        .insert(
          ProjectsCompanion.insert(
            name: projectName,
            description: const Value(
              'Пользователи и задачи с jsonplaceholder.typicode.com',
            ),
            createdAt: now,
            status: ProjectStatus.active,
          ),
        );
    var first = true;
    for (final localId in idByRemote.values.toSet()) {
      await _db
          .into(_db.projectMembers)
          .insert(
            ProjectMembersCompanion.insert(
              projectId: projectId,
              userId: localId,
              role: first ? MemberRole.owner : MemberRole.member,
              joinedAt: now,
            ),
          );
      first = false;
    }

    // 3. Задачи + первая запись истории для каждой
    var tasks = 0;
    for (final t in todos) {
      final status = t.completed ? TaskStatus.done : TaskStatus.todo;
      final taskId = await _db
          .into(_db.tasks)
          .insert(
            TasksCompanion.insert(
              title: t.title,
              description: Value('Импортировано с сервера (todo #${t.id})'),
              projectId: projectId,
              assigneeId: Value(idByRemote[t.userId]),
              status: status,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _db
          .into(_db.taskHistory)
          .insert(
            TaskHistoryCompanion.insert(
              taskId: taskId,
              event: HistoryEvent.created,
              newStatus: status,
              changedAt: now,
              details: const Value('Импорт с сервера'),
            ),
          );
      tasks++;
    }

    return ImportResult(
      projectId: projectId,
      projectName: projectName,
      usersCreated: created,
      usersReused: reused,
      tasksCreated: tasks,
    );
  });
}
