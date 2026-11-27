import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/error_handler.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/server_import/data/datasources/import_local_data_source.dart';
import 'package:lab11/src/server_import/data/datasources/import_remote_data_source.dart';
import 'package:lab11/src/server_import/domain/entities/import_result.dart';
import 'package:lab11/src/server_import/domain/repositories/import_repository.dart';

/// НОВАЯ ФУНКЦИЯ: сервер -> DTO -> локальная база -> ImportResult (сущность).
class ImportRepositoryImpl implements ImportRepository {
  ImportRepositoryImpl(this._remote, this._local);
  final ImportRemoteDataSource _remote;
  final ImportLocalDataSource _local;

  @override
  Future<Either<Failure, ImportResult>> importFromServer({
    required int maxTasks,
  }) => ErrorHandler.guard(() async {
    final users = await _remote.fetchUsers();
    final todos = await _remote.fetchTodos(limit: maxTasks);
    if (users.isEmpty && todos.isEmpty) {
      // Пустой ответ — не ошибка: Presentation покажет Empty State
      return const ImportResult(
        projectId: null,
        projectName: '',
        usersCreated: 0,
        usersReused: 0,
        tasksCreated: 0,
      );
    }
    return _local.save(users, todos);
  });
}
