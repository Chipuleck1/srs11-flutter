import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/domain/entities/server_import/import_result.dart';
import 'package:lab11/src/domain/usecases/server_import/import_from_server_usecase.dart';

sealed class ImportState {
  const ImportState();
}

class ImportInitial extends ImportState {
  const ImportInitial();
}

class ImportLoading extends ImportState {
  const ImportLoading();
}

class ImportSuccess extends ImportState {
  const ImportSuccess(this.result);
  final ImportResult result;
}

/// Сервер ответил, но данных нет.
class ImportEmpty extends ImportState {
  const ImportEmpty();
}

class ImportError extends ImportState {
  const ImportError(this.failure, {required this.canRetry});
  final Failure failure;

  /// Повтор имеет смысл только при временных ошибках (сеть, сервер).
  final bool canRetry;
}

class ImportCubit extends Cubit<ImportState> {
  ImportCubit(this._import) : super(const ImportInitial());

  final ImportFromServerUseCase _import;
  int _lastMaxTasks = 20;

  Future<void> start(int maxTasks) async {
    if (state is ImportLoading) return; // защита от повторного запроса
    _lastMaxTasks = maxTasks;
    emit(const ImportLoading());
    final result = await _import(maxTasks);
    if (isClosed) return;
    emit(
      result.fold(
        (f) => ImportError(
          f,
          canRetry:
              f is NetworkFailure || f is ServerFailure || f is UnknownFailure,
        ),
        (r) => r.isEmpty ? const ImportEmpty() : ImportSuccess(r),
      ),
    );
  }

  /// Повторная отправка неудачного запроса с теми же параметрами.
  Future<void> retry() => start(_lastMaxTasks);

  void reset() => emit(const ImportInitial());
}
