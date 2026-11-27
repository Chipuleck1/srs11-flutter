import 'package:drift/drift.dart';

import 'package:lab11/core/database/app_database.dart';
import 'package:lab11/models/enums.dart';
import 'package:lab11/src/domain/tasks/entities/task.dart';

typedef TaskJoinRow = ({TaskRow task, ProjectRow project, UserRow? assignee});

/// SQL-запросы к задачам и истории. Транзакции тоже живут здесь.
class TaskLocalDataSource {
  TaskLocalDataSource(this._db);

  final AppDatabase _db;

  static final _openStatuses = [
    TaskStatus.todo.name,
    TaskStatus.inProgress.name,
  ];

  // ---------------- чтение ----------------

  JoinedSelectStatement<HasResultSet, dynamic> _joined() =>
      _db.select(_db.tasks).join([
        innerJoin(_db.projects, _db.projects.id.equalsExp(_db.tasks.projectId)),
        leftOuterJoin(_db.users, _db.users.id.equalsExp(_db.tasks.assigneeId)),
      ]);

  TaskJoinRow _row(TypedResult r) => (
    task: r.readTable(_db.tasks),
    project: r.readTable(_db.projects),
    assignee: r.readTableOrNull(_db.users),
  );

  Expression<bool> _where(TaskFilter f) {
    final t = _db.tasks;
    Expression<bool> e = t.deletedAt.isNull();
    if (f.projectId != null) e = e & t.projectId.equals(f.projectId!);
    if (f.assigneeId != null) e = e & t.assigneeId.equals(f.assigneeId!);
    if (f.status != null) e = e & t.status.equals(f.status!.name);
    if (f.priority != null) e = e & t.priority.equals(f.priority!.name);
    final s = f.search.trim();
    if (s.isNotEmpty) {
      e =
          e &
          (containsIgnoreCase(t.title, s) |
              containsIgnoreCase(t.description, s));
    }
    return e;
  }

  List<OrderingTerm> _order(TaskSort sort) {
    final t = _db.tasks;
    return switch (sort) {
      TaskSort.createdDesc => [
        OrderingTerm.desc(t.createdAt),
        OrderingTerm.desc(t.id),
      ],
      TaskSort.createdAsc => [
        OrderingTerm.asc(t.createdAt),
        OrderingTerm.asc(t.id),
      ],
      TaskSort.deadlineAsc => [
        OrderingTerm(expression: t.deadline, nulls: NullsOrder.last),
        OrderingTerm.asc(t.id),
      ],
      TaskSort.deadlineDesc => [
        OrderingTerm(
          expression: t.deadline,
          mode: OrderingMode.desc,
          nulls: NullsOrder.last,
        ),
        OrderingTerm.asc(t.id),
      ],
    };
  }

  /// Фильтры + сортировка + пагинация (LIMIT) + watch().
  Stream<List<TaskJoinRow>> watchTasks(
    TaskFilter filter, {
    required int limit,
  }) {
    final q = _joined()
      ..where(_where(filter))
      ..orderBy(_order(filter.sort))
      ..limit(limit);
    return q.watch().map((rows) => rows.map(_row).toList());
  }

  Stream<int> watchCount(TaskFilter filter) {
    final count = _db.tasks.id.count();
    final q = _db.selectOnly(_db.tasks)
      ..addColumns([count])
      ..where(_where(filter));
    return q.map((r) => r.read(count) ?? 0).watchSingle();
  }

  Stream<TaskJoinRow?> watchTask(int id) {
    final q = _joined()..where(_db.tasks.id.equals(id));
    return q.watchSingleOrNull().map((r) => r == null ? null : _row(r));
  }

  Future<TaskRow?> getTask(int id) =>
      (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<List<({HistoryRow entry, UserRow? user})>> watchHistory(int taskId) {
    final q =
        _db.select(_db.taskHistory).join([
            leftOuterJoin(
              _db.users,
              _db.users.id.equalsExp(_db.taskHistory.changedBy),
            ),
          ])
          ..where(_db.taskHistory.taskId.equals(taskId))
          ..orderBy([
            OrderingTerm.desc(_db.taskHistory.changedAt),
            OrderingTerm.desc(_db.taskHistory.id),
          ]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          (
            entry: r.readTable(_db.taskHistory),
            user: r.readTableOrNull(_db.users),
          ),
      ],
    );
  }

  /// SQL COUNT для правила «не больше 3 задач на один дедлайн».
  Future<int> countOpenTasksOnDay(
    int assigneeId,
    DateTime day, {
    int? excludeTaskId,
  }) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final t = _db.tasks;
    final count = t.id.count();
    var where =
        t.assigneeId.equals(assigneeId) &
        t.deletedAt.isNull() &
        t.status.isIn(_openStatuses) &
        t.deadline.isBiggerOrEqualValue(start) &
        t.deadline.isSmallerThanValue(end);
    if (excludeTaskId != null) where = where & t.id.equals(excludeTaskId).not();
    final row =
        await (_db.selectOnly(t)
              ..addColumns([count])
              ..where(where))
            .getSingle();
    return row.read(count) ?? 0;
  }

  Future<HistoryRow?> lastRevertibleStatusChange(int taskId) =>
      (_db.select(_db.taskHistory)
            ..where(
              (h) =>
                  h.taskId.equals(taskId) &
                  h.event.equals(HistoryEvent.statusChanged.name) &
                  h.reverted.equals(false),
            )
            ..orderBy([(h) => OrderingTerm.desc(h.id)])
            ..limit(1))
          .getSingleOrNull();

  // ---------------- запись (транзакции) ----------------

  /// Задача и первая запись истории — одна транзакция:
  /// если история не сохранится, задача тоже не сохранится.
  Future<int> createTask(TaskDraft d, {required int? actorId}) =>
      _db.transaction(() async {
        final now = DateTime.now();
        final id = await _db
            .into(_db.tasks)
            .insert(
              TasksCompanion.insert(
                title: d.title,
                description: Value(d.description),
                projectId: d.projectId!,
                assigneeId: Value(d.assigneeId),
                priority: Value(d.priority),
                status: d.status,
                deadline: Value(d.deadline),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await _addHistory(id, HistoryEvent.created, null, d.status, actorId);
        return id;
      });

  Future<void> updateTask(
    int id, {
    required String title,
    required String description,
    required TaskPriority priority,
    DateTime? deadline,
  }) => (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
    TasksCompanion(
      title: Value(title),
      description: Value(description),
      priority: Value(priority),
      deadline: Value(deadline),
      updatedAt: Value(DateTime.now()),
    ),
  );

  Future<void> changePriority(int id, TaskPriority priority) =>
      (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          priority: Value(priority),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> changeStatus(
    int id,
    TaskStatus status, {
    required int? actorId,
  }) => _db.transaction(() async {
    final task = (await getTask(id))!;
    await _setStatus(id, status);
    await _addHistory(
      id,
      HistoryEvent.statusChanged,
      task.status,
      status,
      actorId,
    );
  });

  Future<void> reassign(
    int id,
    int? assigneeId, {
    required int? actorId,
  }) => _db.transaction(() async {
    final task = (await getTask(id))!;
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        assigneeId: Value(assigneeId),
        updatedAt: Value(DateTime.now()),
      ),
    );
    final details =
        '${await _userName(task.assigneeId)} → ${await _userName(assigneeId)}';
    await _addHistory(
      id,
      HistoryEvent.assigneeChanged,
      task.status,
      task.status,
      actorId,
      details: details,
    );
  });

  /// Undo: вернуть статус, пометить запись отменённой и записать событие.
  Future<void> revertStatusChange(int historyId, {required int? actorId}) =>
      _db.transaction(() async {
        final entry = await (_db.select(
          _db.taskHistory,
        )..where((h) => h.id.equals(historyId))).getSingle();
        final task = (await getTask(entry.taskId))!;
        await _setStatus(entry.taskId, entry.oldStatus!);
        await (_db.update(_db.taskHistory)
              ..where((h) => h.id.equals(historyId)))
            .write(const TaskHistoryCompanion(reverted: Value(true)));
        await _addHistory(
          entry.taskId,
          HistoryEvent.undo,
          task.status,
          entry.oldStatus!,
          actorId,
          details:
              'Отменено: ${entry.oldStatus!.label} → ${entry.newStatus.label}',
        );
      });

  Future<void> softDelete(int id) =>
      (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(deletedAt: Value(DateTime.now())),
      );

  // ---------------- helpers ----------------

  Future<void> _setStatus(int id, TaskStatus status) =>
      (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(status: Value(status), updatedAt: Value(DateTime.now())),
      );

  Future<void> _addHistory(
    int taskId,
    HistoryEvent event,
    TaskStatus? oldStatus,
    TaskStatus newStatus,
    int? actorId, {
    String? details,
  }) => _db
      .into(_db.taskHistory)
      .insert(
        TaskHistoryCompanion.insert(
          taskId: taskId,
          event: event,
          oldStatus: Value(oldStatus),
          newStatus: newStatus,
          changedBy: Value(actorId),
          changedAt: DateTime.now(),
          details: Value(details),
        ),
      );

  Future<String> _userName(int? id) async {
    if (id == null) return 'не назначен';
    final u = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(id))).getSingleOrNull();
    return u?.name ?? 'удалён';
  }
}
