import 'dart:async';

import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/domain/usecases/projects/project_usecases.dart';
import 'package:lab11/src/domain/entities/users/user.dart';
import 'package:lab11/src/domain/usecases/users/user_usecases.dart';

/// Выбор пользователя с поиском (или только участников проекта).
class UserPickerCubit extends WatchCubit<List<User>> {
  UserPickerCubit(
    this._users,
    this._members, {
    this.projectId,
    this.excludeProjectId,
  }) {
    _init();
  }
  final WatchUsersUseCase _users;
  final GetProjectMembersUseCase _members;
  final int? projectId;
  final int? excludeProjectId;

  String _search = '';
  Set<int> _excluded = {};

  Future<void> _init() async {
    if (excludeProjectId != null) {
      _excluded = (await _members(excludeProjectId!))
          .getOrElse((_) => [])
          .map((u) => u.id)
          .toSet();
    }
    if (!isClosed) load();
  }

  @override
  Stream<Either<Failure, List<User>>> source() {
    final s = _search.toLowerCase();
    final base = projectId != null
        ? Stream.fromFuture(_members(projectId!)).map(
            (e) => e.map(
              (list) => list
                  .where(
                    (u) =>
                        u.name.toLowerCase().contains(s) || u.email.contains(s),
                  )
                  .toList(),
            ),
          )
        : _users((search: _search, limit: 100));
    return base.map(
      (e) => e.map(
        (list) => list.where((u) => !_excluded.contains(u.id)).toList(),
      ),
    );
  }

  void search(String value) {
    _search = value.trim();
    load();
  }
}
