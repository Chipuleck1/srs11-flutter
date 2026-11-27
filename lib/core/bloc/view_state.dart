import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';

/// Состояния экрана: Initial → Loading → Loaded / Empty / Error.
sealed class ViewState<T> {
  const ViewState();
}

class ViewInitial<T> extends ViewState<T> {
  const ViewInitial();
}

class ViewLoading<T> extends ViewState<T> {
  const ViewLoading();
}

class ViewLoaded<T> extends ViewState<T> {
  const ViewLoaded(this.data);
  final T data;
}

class ViewEmpty<T> extends ViewState<T> {
  const ViewEmpty();
}

class ViewError<T> extends ViewState<T> {
  const ViewError(this.failure);
  final Failure failure;

  /// Понятный пользователю текст (технические детали остаются в логах).
  String get message => failure.message;
}

/// Базовый Cubit для реактивных данных (Drift watch() → UseCase → Cubit).
/// Подписывается на поток и превращает Either в ViewState.
abstract class WatchCubit<T> extends Cubit<ViewState<T>> {
  WatchCubit() : super(const ViewInitial());

  StreamSubscription<Either<Failure, T>>? _sub;

  /// Источник данных — вызов StreamUseCase.
  Stream<Either<Failure, T>> source();

  /// Когда показывать Empty State.
  bool isEmpty(T data) => data == null || (data is Iterable && data.isEmpty);

  void load() {
    _sub?.cancel();
    if (state is! ViewLoaded<T>) {
      emit(const ViewLoading()); // не мигаем при перезагрузке
    }
    _sub = source().listen((result) {
      if (isClosed) return;
      emit(
        result.fold(
          ViewError<T>.new,
          (d) => isEmpty(d) ? ViewEmpty<T>() : ViewLoaded<T>(d),
        ),
      );
    });
  }

  /// Повторная загрузка (кнопка «Повторить»).
  void retry() {
    emit(const ViewLoading());
    load();
  }

  /// Выполняет действие UseCase; возвращает Failure или null при успехе.
  Future<Failure?> act(Future<Either<Failure, Object?>> action) async =>
      (await action).fold((f) => f, (_) => null);

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}

/// WatchCubit для простых случаев: источник передаётся функцией.
class StreamCubit<T> extends WatchCubit<T> {
  StreamCubit(this._source, {this._emptyWhen}) {
    load();
  }

  final Stream<Either<Failure, T>> Function() _source;
  final bool Function(T)? _emptyWhen;

  @override
  Stream<Either<Failure, T>> source() => _source();

  @override
  bool isEmpty(T data) => _emptyWhen?.call(data) ?? super.isEmpty(data);
}

/// Выполняет действие вне WatchCubit (Failure или null).
Future<Failure?> runUseCase(Future<Either<Failure, Object?>> action) async =>
    (await action).fold((f) => f, (_) => null);
