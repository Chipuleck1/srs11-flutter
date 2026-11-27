import 'package:drift/drift.dart';

import 'package:lab11/core/database/app_database.dart';
import 'package:lab11/models/enums.dart';
import 'package:lab11/src/domain/entities/dashboard/dashboard_stats.dart';

/// Статистика считается SQL-запросами прямо в SQLite.
class StatsLocalDataSource {
  StatsLocalDataSource(this._db);

  final AppDatabase _db;

  /// Пересчёт при любом изменении связанных таблиц.
  Stream<DashboardStats> watchDashboard() async* {
    yield await load();
    yield* _db
        .tableUpdates(
          TableUpdateQuery.onAllTables([
            _db.tasks,
            _db.projects,
            _db.users,
            _db.projectMembers,
          ]),
        )
        .asyncMap((_) => load());
  }

  Future<DashboardStats> load() async {
    final totals = await _db
        .customSelect(
          '''
      SELECT
        (SELECT COUNT(*) FROM projects) AS projects,
        COUNT(*) AS tasks,
        COALESCE(SUM(status = 'done'), 0) AS done,
        COALESCE(SUM(status IN ('todo', 'inProgress')), 0) AS open,
        COALESCE(SUM(status IN ('todo', 'inProgress')
          AND deadline IS NOT NULL AND deadline < ?), 0) AS overdue
      FROM tasks WHERE deleted_at IS NULL
      ''',
          variables: [Variable.withDateTime(DateTime.now())],
        )
        .getSingle();

    final priorityRows = await _db
        .customSelect(
          'SELECT priority, COUNT(*) AS cnt FROM tasks WHERE deleted_at IS NULL GROUP BY priority',
        )
        .get();
    final byPriority = {for (final p in TaskPriority.values) p: 0};
    for (final r in priorityRows) {
      byPriority[TaskPriority.values.byName(r.read<String>('priority'))] = r
          .read<int>('cnt');
    }

    final assigneeRows = await _db.customSelect('''
      SELECT t.assignee_id AS uid, COALESCE(u.name, 'Не назначено') AS name, COUNT(*) AS cnt
      FROM tasks t LEFT JOIN users u ON u.id = t.assignee_id
      WHERE t.deleted_at IS NULL
      GROUP BY t.assignee_id
      ORDER BY cnt DESC, name
      ''').get();

    final progressRows = await _db.customSelect('''
      SELECT p.id, p.name, COUNT(t.id) AS total, COALESCE(SUM(t.status = 'done'), 0) AS done
      FROM projects p
      LEFT JOIN tasks t ON t.project_id = p.id AND t.deleted_at IS NULL
      GROUP BY p.id
      ORDER BY p.name
      ''').get();

    return DashboardStats(
      projects: totals.read<int>('projects'),
      tasks: totals.read<int>('tasks'),
      done: totals.read<int>('done'),
      open: totals.read<int>('open'),
      overdue: totals.read<int>('overdue'),
      byPriority: byPriority,
      byAssignee: [
        for (final r in assigneeRows)
          AssigneeCount(
            r.read<int?>('uid'),
            r.read<String>('name'),
            r.read<int>('cnt'),
          ),
      ],
      projectProgress: [
        for (final r in progressRows)
          ProjectProgress(
            r.read<int>('id'),
            r.read<String>('name'),
            r.read<int>('total'),
            r.read<int>('done'),
          ),
      ],
    );
  }
}
