import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/core/usecase/usecase.dart';
import 'package:lab11/src/tasks/domain/entities/task.dart';
import 'package:lab11/src/trash/domain/repositories/trash_repository.dart';

class WatchTrashUseCase implements StreamUseCase<List<TaskDetails>, NoParams> {
  WatchTrashUseCase(this._repo);
  final TrashRepository _repo;

  @override
  Stream<Either<Failure, List<TaskDetails>>> call(NoParams _) =>
      _repo.watchTrash();
}

/// Восстановить задачу из корзины.
class RestoreTaskUseCase implements UseCase<Unit, int> {
  RestoreTaskUseCase(this._repo);
  final TrashRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(int id) => eitherDo(($) async {
    if (!await $(_repo.exists(id))) {
      fail(const NotFoundFailure('Задача не найдена'));
    }
    return $(_repo.restore(id));
  });
}

/// Удалить навсегда (комментарии, вложения и история — каскадно).
class DeleteTaskForeverUseCase implements UseCase<Unit, int> {
  DeleteTaskForeverUseCase(this._repo);
  final TrashRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(int id) => _repo.deleteForever(id);
}

class EmptyTrashUseCase implements UseCase<Unit, NoParams> {
  EmptyTrashUseCase(this._repo);
  final TrashRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams _) => _repo.emptyTrash();
}
