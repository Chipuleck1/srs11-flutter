import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/error_handler.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/domain/entities/tasks/task.dart';
import 'package:lab11/src/data/datasources/trash/trash_local_data_source.dart';
import 'package:lab11/src/domain/repositories/trash/trash_repository.dart';
import 'package:lab11/src/domain/entities/users/user.dart';

class TrashRepositoryImpl implements TrashRepository {
  TrashRepositoryImpl(this._local);
  final TrashLocalDataSource _local;

  Future<Either<Failure, Unit>> _run(Future<void> Function() action) =>
      ErrorHandler.guard(() async {
        await action();
        return unit;
      });

  @override
  Stream<Either<Failure, List<TaskDetails>>> watchTrash() =>
      ErrorHandler.guardStream(
        _local.watchTrash().map(
          (rows) => [for (final r in rows) _toDetails(r)],
        ),
      );

  @override
  Future<Either<Failure, bool>> exists(int taskId) =>
      ErrorHandler.guard(() => _local.exists(taskId));

  @override
  Future<Either<Failure, Unit>> restore(int taskId) =>
      _run(() => _local.restore(taskId));

  @override
  Future<Either<Failure, Unit>> deleteForever(int taskId) =>
      _run(() => _local.deleteForever(taskId));

  @override
  Future<Either<Failure, Unit>> emptyTrash() => _run(_local.emptyTrash);

  // ---------- маппинг строк БД в сущности (своя копия для фичи «Корзина») ----------

  TaskDetails _toDetails(TrashRow r) => TaskDetails(
    task: Task(
      id: r.task.id,
      title: r.task.title,
      description: r.task.description,
      projectId: r.task.projectId,
      assigneeId: r.task.assigneeId,
      priority: r.task.priority,
      status: r.task.status,
      deadline: r.task.deadline,
      createdAt: r.task.createdAt,
      updatedAt: r.task.updatedAt,
      deletedAt: r.task.deletedAt,
    ),
    projectName: r.project.name,
    assignee: r.assignee == null
        ? null
        : User(
            id: r.assignee!.id,
            name: r.assignee!.name,
            email: r.assignee!.email,
            registeredAt: r.assignee!.registeredAt,
          ),
  );
}
