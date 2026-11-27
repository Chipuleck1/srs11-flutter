import 'dart:async';

import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/domain/entities/users/user.dart';
import 'package:lab11/src/domain/usecases/users/user_usecases.dart';

class UserDetailCubit extends WatchCubit<User?> {
  UserDetailCubit(this.userId, this._watch) {
    load();
  }
  final int userId;
  final WatchUserUseCase _watch;

  @override
  Stream<Either<Failure, User?>> source() => _watch(userId);
}
