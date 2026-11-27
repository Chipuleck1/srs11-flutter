import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/core/usecase/usecase.dart';
import 'package:lab11/src/domain/server_import/entities/import_result.dart';
import 'package:lab11/src/domain/server_import/repositories/import_repository.dart';

// ---------------- НОВАЯ ФУНКЦИЯ: импорт с сервера ----------------

/// Загружает пользователей и задачи с сервера и сохраняет их в новый проект.
class ImportFromServerUseCase implements UseCase<ImportResult, int> {
  ImportFromServerUseCase(this._repo);
  final ImportRepository _repo;

  /// [maxTasks] — сколько задач взять с сервера (1…200).
  @override
  Future<Either<Failure, ImportResult>> call(int maxTasks) {
    if (maxTasks < 1 || maxTasks > 200) {
      return Future.value(
        const Left(ValidationFailure('Количество задач: от 1 до 200')),
      );
    }
    return _repo.importFromServer(maxTasks: maxTasks);
  }
}
