import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/server_import/domain/entities/import_result.dart';

/// НОВАЯ ФУНКЦИЯ: импорт пользователей и задач с сервера (JSONPlaceholder).
abstract interface class ImportRepository {
  Future<Either<Failure, ImportResult>> importFromServer({
    required int maxTasks,
  });
}
