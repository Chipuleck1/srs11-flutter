import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/domain/server_import/entities/import_result.dart';

/// НОВАЯ ФУНКЦИЯ: импорт пользователей и задач с сервера (JSONPlaceholder).
abstract interface class ImportRepository {
  Future<Either<Failure, ImportResult>> importFromServer({
    required int maxTasks,
  });
}
