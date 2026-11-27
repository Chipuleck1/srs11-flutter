import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/error_handler.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/data/datasources/users/user_local_data_source.dart';
import 'package:lab11/src/data/mapper/users/user_mapper.dart';
import 'package:lab11/src/domain/entities/users/user.dart';
import 'package:lab11/src/domain/repositories/users/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._local);
  final UserLocalDataSource _local;

  @override
  Stream<Either<Failure, List<User>>> watchUsers({
    String search = '',
    int? limit,
  }) => ErrorHandler.guardStream(
    _local
        .watchUsers(search: search, limit: limit)
        .map((rows) => rows.map((r) => r.toEntity()).toList()),
  );

  @override
  Stream<Either<Failure, User?>> watchUser(int id) =>
      ErrorHandler.guardStream(_local.watchUser(id).map((r) => r?.toEntity()));

  @override
  Future<Either<Failure, User?>> getUser(int id) =>
      ErrorHandler.guard(() async => (await _local.getUser(id))?.toEntity());

  @override
  Future<Either<Failure, bool>> emailExists(String email, {int? exceptId}) =>
      ErrorHandler.guard(() => _local.emailExists(email, exceptId: exceptId));

  @override
  Future<Either<Failure, int>> createUser({
    required String name,
    required String email,
    DateTime? registeredAt,
  }) => ErrorHandler.guard(
    () => _local.insert(name: name, email: email, registeredAt: registeredAt),
  );

  @override
  Future<Either<Failure, Unit>> updateUser(
    int id, {
    required String name,
    required String email,
  }) => ErrorHandler.guard(() async {
    await _local.update(id, name: name, email: email);
    return unit;
  });

  @override
  Future<Either<Failure, int>> countOpenTasks(int userId) =>
      ErrorHandler.guard(() => _local.countOpenTasks(userId));

  @override
  Future<Either<Failure, Unit>> deleteUser(int id) =>
      ErrorHandler.guard(() async {
        await _local.delete(id);
        return unit;
      });
}
