import 'package:drift/drift.dart';

import 'package:lab11/core/database/app_database.dart';

typedef TrashRow = ({TaskRow task, ProjectRow project, UserRow? assignee});

/// SQL-запросы корзины.
class TrashLocalDataSource {
  TrashLocalDataSource(this._db);

  final AppDatabase _db;

  /// Удалённые задачи (deleted_at IS NOT NULL) + проект + исполнитель.
  Stream<List<TrashRow>> watchTrash() {
    final q =
        _db.select(_db.tasks).join([
            innerJoin(
              _db.projects,
              _db.projects.id.equalsExp(_db.tasks.projectId),
            ),
            leftOuterJoin(
              _db.users,
              _db.users.id.equalsExp(_db.tasks.assigneeId),
            ),
          ])
          ..where(_db.tasks.deletedAt.isNotNull())
          ..orderBy([OrderingTerm.desc(_db.tasks.deletedAt)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          (
            task: r.readTable(_db.tasks),
            project: r.readTable(_db.projects),
            assignee: r.readTableOrNull(_db.users),
          ),
      ],
    );
  }

  Future<bool> exists(int id) async =>
      await (_db.select(
        _db.tasks,
      )..where((t) => t.id.equals(id))).getSingleOrNull() !=
      null;

  Future<void> restore(int id) =>
      (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          deletedAt: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Комментарии, вложения и история удаляются каскадно (ON DELETE CASCADE).
  Future<void> deleteForever(int id) =>
      (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();

  Future<void> emptyTrash() =>
      (_db.delete(_db.tasks)..where((t) => t.deletedAt.isNotNull())).go();
}
