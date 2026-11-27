import 'dart:async';

import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/domain/users/entities/user.dart';
import 'package:lab11/src/domain/users/usecases/user_usecases.dart';

// ---------------- пользователи ----------------

class UsersCubit extends WatchCubit<List<User>> {
  UsersCubit(this._watch, this._create, this._update, this._delete) {
    load();
  }
  final WatchUsersUseCase _watch;
  final CreateUserUseCase _create;
  final UpdateUserUseCase _update;
  final DeleteUserUseCase _delete;

  static const pageSize = 50;
  String _search = '';
  int limit = pageSize;

  @override
  Stream<Either<Failure, List<User>>> source() =>
      _watch((search: _search, limit: limit));

  void search(String value) {
    _search = value;
    limit = pageSize;
    load();
  }

  void loadMore() {
    final s = state;
    if (s is ViewLoaded<List<User>> && s.data.length >= limit) {
      limit += pageSize;
      load();
    }
  }

  Future<Either<Failure, int>> create(String name, String email) =>
      _create((name: name, email: email));
  Future<Failure?> update(int id, String name, String email) =>
      act(_update((id: id, name: name, email: email)));
  Future<Failure?> delete(int id) => act(_delete(id));
}
