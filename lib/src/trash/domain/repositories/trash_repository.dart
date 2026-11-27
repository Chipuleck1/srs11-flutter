import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/tasks/domain/entities/task.dart';

/// Корзина: задачи, удалённые через soft delete (deletedAt заполнен).
abstract interface class TrashRepository {
  Stream<Either<Failure, List<TaskDetails>>> watchTrash();
  Future<Either<Failure, bool>> exists(int taskId);
  Future<Either<Failure, Unit>> restore(int taskId);
  Future<Either<Failure, Unit>> deleteForever(int taskId);
  Future<Either<Failure, Unit>> emptyTrash();
}
