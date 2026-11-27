import 'dart:async';

import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/core/usecase/usecase.dart';
import 'package:lab11/src/domain/trash/entities/trash_item.dart';
import 'package:lab11/src/domain/trash/usecases/trash_usecases.dart';

// ---------------- корзина ----------------

class TrashCubit extends WatchCubit<List<TrashItem>> {
  TrashCubit(this._watch, this._restore, this._delete, this._empty) {
    load();
  }
  final WatchTrashUseCase _watch;
  final RestoreTaskUseCase _restore;
  final DeleteTaskForeverUseCase _delete;
  final EmptyTrashUseCase _empty;

  @override
  Stream<Either<Failure, List<TrashItem>>> source() =>
      _watch(const NoParams());

  Future<Failure?> restore(int id) => act(_restore(id));
  Future<Failure?> deleteForever(int id) => act(_delete(id));
  Future<Failure?> emptyTrash() => act(_empty(const NoParams()));
}
