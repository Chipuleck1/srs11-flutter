import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/core/usecase/usecase.dart';
import 'package:lab11/core/validation/validators.dart';
import 'package:lab11/src/domain/users/entities/user.dart';
import 'package:lab11/src/domain/users/repositories/user_repository.dart';

class WatchUsersUseCase
    implements StreamUseCase<List<User>, ({String search, int? limit})> {
  WatchUsersUseCase(this._repo);
  final UserRepository _repo;

  @override
  Stream<Either<Failure, List<User>>> call(({String search, int? limit}) p) =>
      _repo.watchUsers(search: p.search, limit: p.limit);
}

class WatchUserUseCase implements StreamUseCase<User?, int> {
  WatchUserUseCase(this._repo);
  final UserRepository _repo;

  @override
  Stream<Either<Failure, User?>> call(int id) => _repo.watchUser(id);
}

class GetUserUseCase implements UseCase<User?, int> {
  GetUserUseCase(this._repo);
  final UserRepository _repo;

  @override
  Future<Either<Failure, User?>> call(int id) => _repo.getUser(id);
}

/// Создание пользователя: проверка имени, формата и уникальности email.
class CreateUserUseCase implements UseCase<int, ({String name, String email})> {
  CreateUserUseCase(this._repo);
  final UserRepository _repo;

  @override
  Future<Either<Failure, int>> call(({String name, String email}) p) =>
      eitherDo(($) async {
        final name = await $(Validators.text(p.name, 'Имя', max: 100));
        final email = await $(Validators.email(p.email));
        if (await $(_repo.emailExists(email))) {
          fail(const DuplicateEmailFailure());
        }
        return $(_repo.createUser(name: name, email: email));
      });
}

class UpdateUserUseCase
    implements UseCase<Unit, ({int id, String name, String email})> {
  UpdateUserUseCase(this._repo);
  final UserRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(({int id, String name, String email}) p) =>
      eitherDo(($) async {
        final name = await $(Validators.text(p.name, 'Имя', max: 100));
        final email = await $(Validators.email(p.email));
        if (await $(_repo.emailExists(email, exceptId: p.id))) {
          fail(const DuplicateEmailFailure());
        }
        return $(_repo.updateUser(p.id, name: name, email: email));
      });
}

/// Удалять пользователя с незавершёнными задачами запрещено.
class DeleteUserUseCase implements UseCase<Unit, int> {
  DeleteUserUseCase(this._repo);
  final UserRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(int id) => eitherDo(($) async {
    final open = await $(_repo.countOpenTasks(id));
    if (open > 0) fail(UserHasOpenTasksFailure(open));
    return $(_repo.deleteUser(id));
  });
}
