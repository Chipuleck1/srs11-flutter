import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';

/// Кто сейчас работает с приложением (сохраняется между запусками).
abstract interface class SessionRepository {
  Future<Either<Failure, int?>> getCurrentUserId();
  Future<Either<Failure, Unit>> setCurrentUserId(int? id);
}
