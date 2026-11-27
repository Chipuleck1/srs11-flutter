import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/core/usecase/usecase.dart';
import 'package:lab11/src/home/domain/repositories/session_repository.dart';

// ---------------- текущий пользователь ----------------

class GetCurrentUserIdUseCase implements UseCase<int?, NoParams> {
  GetCurrentUserIdUseCase(this._repo);
  final SessionRepository _repo;

  @override
  Future<Either<Failure, int?>> call(NoParams _) => _repo.getCurrentUserId();
}

class SetCurrentUserIdUseCase implements UseCase<Unit, int?> {
  SetCurrentUserIdUseCase(this._repo);
  final SessionRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(int? id) => _repo.setCurrentUserId(id);
}
