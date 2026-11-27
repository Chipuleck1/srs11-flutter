import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/error_handler.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/models/enums.dart';
import 'package:lab11/src/data/datasources/tasks/task_local_data_source.dart';
import 'package:lab11/src/data/mapper/tasks/task_mapper.dart';
import 'package:lab11/src/domain/entities/tasks/task.dart';
import 'package:lab11/src/domain/repositories/tasks/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._local);
  final TaskLocalDataSource _local;

  Future<Either<Failure, Unit>> _run(Future<void> Function() action) =>
      ErrorHandler.guard(() async {
        await action();
        return unit;
      });

  List<TaskDetails> _details(List<TaskJoinRow> rows) => [
    for (final r in rows) toTaskDetails(r.task, r.project, r.assignee),
  ];

  @override
  Stream<Either<Failure, List<TaskDetails>>> watchTasks(
    TaskFilter filter, {
    required int limit,
  }) => ErrorHandler.guardStream(
    _local.watchTasks(filter, limit: limit).map(_details),
  );

  @override
  Stream<Either<Failure, int>> watchCount(TaskFilter filter) =>
      ErrorHandler.guardStream(_local.watchCount(filter));

  @override
  Stream<Either<Failure, TaskDetails?>> watchTask(int id) =>
      ErrorHandler.guardStream(
        _local
            .watchTask(id)
            .map(
              (r) => r == null
                  ? null
                  : toTaskDetails(r.task, r.project, r.assignee),
            ),
      );

  @override
  Future<Either<Failure, Task?>> getTask(int id) =>
      ErrorHandler.guard(() async => (await _local.getTask(id))?.toEntity());

  @override
  Stream<Either<Failure, List<HistoryEntry>>> watchHistory(int taskId) =>
      ErrorHandler.guardStream(
        _local
            .watchHistory(taskId)
            .map(
              (rows) => [for (final r in rows) r.entry.toEntity(user: r.user)],
            ),
      );

  @override
  Future<Either<Failure, int>> countOpenTasksOnDay(
    int assigneeId,
    DateTime day, {
    int? excludeTaskId,
  }) => ErrorHandler.guard(
    () => _local.countOpenTasksOnDay(
      assigneeId,
      day,
      excludeTaskId: excludeTaskId,
    ),
  );

  @override
  Future<Either<Failure, int>> createTask(
    TaskDraft draft, {
    required int? actorId,
  }) => ErrorHandler.guard(() => _local.createTask(draft, actorId: actorId));

  @override
  Future<Either<Failure, Unit>> updateTask(
    int id, {
    required String title,
    required String description,
    required TaskPriority priority,
    DateTime? deadline,
  }) => _run(
    () => _local.updateTask(
      id,
      title: title,
      description: description,
      priority: priority,
      deadline: deadline,
    ),
  );

  @override
  Future<Either<Failure, Unit>> changePriority(int id, TaskPriority priority) =>
      _run(() => _local.changePriority(id, priority));

  @override
  Future<Either<Failure, Unit>> changeStatus(
    int id,
    TaskStatus status, {
    required int? actorId,
  }) => _run(() => _local.changeStatus(id, status, actorId: actorId));

  @override
  Future<Either<Failure, Unit>> reassign(
    int id,
    int? assigneeId, {
    required int? actorId,
  }) => _run(() => _local.reassign(id, assigneeId, actorId: actorId));

  @override
  Future<Either<Failure, HistoryEntry?>> lastRevertibleStatusChange(
    int taskId,
  ) => ErrorHandler.guard(
    () async => (await _local.lastRevertibleStatusChange(taskId))?.toEntity(),
  );

  @override
  Future<Either<Failure, Unit>> revertStatusChange(
    HistoryEntry entry, {
    required int? actorId,
  }) => _run(() => _local.revertStatusChange(entry.id, actorId: actorId));

  @override
  Future<Either<Failure, Unit>> softDelete(int id) =>
      _run(() => _local.softDelete(id));
}
