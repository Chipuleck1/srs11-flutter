import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/domain/home/entities/session.dart';

/// Кто сейчас работает с приложением (сохраняется между запусками).
abstract interface class SessionRepository {
  Future<Either<Failure, Session>> getSession();
  Future<Either<Failure, Unit>> setCurrentUserId(int? id);
}
