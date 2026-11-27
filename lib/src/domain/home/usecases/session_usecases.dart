import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/core/usecase/usecase.dart';
import 'package:lab11/src/domain/home/entities/session.dart';
import 'package:lab11/src/domain/home/repositories/session_repository.dart';

// ---------------- текущий пользователь ----------------

class GetSessionUseCase implements UseCase<Session, NoParams> {
  GetSessionUseCase(this._repo);
  final SessionRepository _repo;

  @override
  Future<Either<Failure, Session>> call(NoParams _) => _repo.getSession();
}

class SetCurrentUserIdUseCase implements UseCase<Unit, int?> {
  SetCurrentUserIdUseCase(this._repo);
  final SessionRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(int? id) => _repo.setCurrentUserId(id);
}
