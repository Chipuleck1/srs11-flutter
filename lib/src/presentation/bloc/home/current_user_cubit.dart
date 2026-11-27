import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/core/usecase/usecase.dart';
import 'package:lab11/src/domain/usecases/home/session_usecases.dart';

/// Текущий пользователь приложения.
class CurrentUserCubit extends Cubit<int?> {
  CurrentUserCubit(this._get, this._set) : super(null);

  final GetCurrentUserIdUseCase _get;
  final SetCurrentUserIdUseCase _set;

  Future<void> init() async =>
      emit((await _get(const NoParams())).getOrElse((_) => null));

  Future<void> select(int? id) async {
    await _set(id);
    emit(id);
  }
}
