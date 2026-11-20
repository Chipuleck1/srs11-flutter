import 'package:fpdart/fpdart.dart' hide Task;

import '../../../core/error/failures.dart';
import '../entities/entities.dart';

/// НОВАЯ ФУНКЦИЯ: импорт пользователей и задач с сервера (JSONPlaceholder).
abstract interface class ImportRepository {
  Future<Either<Failure, ImportResult>> importFromServer({
    required int maxTasks,
  });
}
