import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/error_handler.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/domain/home/entities/session.dart';
import 'package:lab11/src/data/home/datasources/session_local_data_source.dart';
import 'package:lab11/src/domain/home/repositories/session_repository.dart';

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this._local);
  final SessionLocalDataSource _local;

  @override
  Future<Either<Failure, Session>> getSession() => ErrorHandler.guard(
    () async => Session(currentUserId: _local.getCurrentUserId()),
  );

  @override
  Future<Either<Failure, Unit>> setCurrentUserId(int? id) =>
      ErrorHandler.guard(() async {
        await _local.setCurrentUserId(id);
        return unit;
      });
}
