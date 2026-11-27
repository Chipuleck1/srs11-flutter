import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/domain/trash/entities/trash_item.dart';

/// Корзина: задачи, удалённые через soft delete (deletedAt заполнен).
abstract interface class TrashRepository {
  Stream<Either<Failure, List<TrashItem>>> watchTrash();
  Future<Either<Failure, bool>> exists(int taskId);
  Future<Either<Failure, Unit>> restore(int taskId);
  Future<Either<Failure, Unit>> deleteForever(int taskId);
  Future<Either<Failure, Unit>> emptyTrash();
}
