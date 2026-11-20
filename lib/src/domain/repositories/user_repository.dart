import 'package:fpdart/fpdart.dart' hide Task;

import '../../../core/error/failures.dart';
import '../entities/entities.dart';

/// Абстракция Domain: что умеет хранилище пользователей.
/// Реализация — в Data Layer (UserRepositoryImpl).
abstract interface class UserRepository {
  Stream<Either<Failure, List<User>>> watchUsers({
    String search = '',
    int? limit,
  });
  Stream<Either<Failure, User?>> watchUser(int id);
  Future<Either<Failure, User?>> getUser(int id);
  Future<Either<Failure, bool>> emailExists(String email, {int? exceptId});
  Future<Either<Failure, int>> createUser({
    required String name,
    required String email,
    DateTime? registeredAt,
  });
  Future<Either<Failure, Unit>> updateUser(
    int id, {
    required String name,
    required String email,
  });
  Future<Either<Failure, int>> countOpenTasks(int userId);
  Future<Either<Failure, Unit>> deleteUser(int id);
}
