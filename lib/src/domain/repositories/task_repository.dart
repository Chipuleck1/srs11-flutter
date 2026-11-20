import 'package:fpdart/fpdart.dart' hide Task;

import '../../../core/error/failures.dart';
import '../entities/entities.dart';

abstract interface class TaskRepository {
  Stream<Either<Failure, List<TaskDetails>>> watchTasks(
    TaskFilter filter, {
    required int limit,
  });
  Stream<Either<Failure, int>> watchCount(TaskFilter filter);
  Stream<Either<Failure, TaskDetails?>> watchTask(int id);
  Future<Either<Failure, Task?>> getTask(int id);
  Stream<Either<Failure, List<TaskDetails>>> watchTrash();
  Stream<Either<Failure, List<HistoryEntry>>> watchHistory(int taskId);

  /// Сколько незавершённых задач у исполнителя с дедлайном в этот день.
  Future<Either<Failure, int>> countOpenTasksOnDay(
    int assigneeId,
    DateTime day, {
    int? excludeTaskId,
  });

  /// Задача + первая запись истории — в одной транзакции.
  Future<Either<Failure, int>> createTask(
    TaskDraft draft, {
    required int? actorId,
  });
  Future<Either<Failure, Unit>> updateTask(
    int id, {
    required String title,
    required String description,
    required TaskPriority priority,
    DateTime? deadline,
  });
  Future<Either<Failure, Unit>> changePriority(int id, TaskPriority priority);

  /// Новый статус + запись в историю — в одной транзакции.
  Future<Either<Failure, Unit>> changeStatus(
    int id,
    TaskStatus status, {
    required int? actorId,
  });

  /// Новый исполнитель + запись в историю — в одной транзакции.
  Future<Either<Failure, Unit>> reassign(
    int id,
    int? assigneeId, {
    required int? actorId,
  });

  /// Последняя ещё не отменённая смена статуса.
  Future<Either<Failure, HistoryEntry?>> lastRevertibleStatusChange(int taskId);

  /// Возврат статуса из [entry] + отметка и запись в историю — атомарно.
  Future<Either<Failure, Unit>> revertStatusChange(
    HistoryEntry entry, {
    required int? actorId,
  });

  Future<Either<Failure, Unit>> softDelete(int id);
  Future<Either<Failure, Unit>> restore(int id);
  Future<Either<Failure, Unit>> deleteForever(int id);
  Future<Either<Failure, Unit>> emptyTrash();
}
