import 'package:fpdart/fpdart.dart' hide Task;

import '../../../core/error/error_handler.dart';
import '../../../core/error/failures.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/demo_data_repository.dart';
import '../../domain/repositories/import_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/stats_repository.dart';
import '../datasources/demo_local_data_source.dart';
import '../datasources/import_local_data_source.dart';
import '../datasources/import_remote_data_source.dart';
import '../datasources/session_local_data_source.dart';
import '../datasources/stats_local_data_source.dart';

class StatsRepositoryImpl implements StatsRepository {
  StatsRepositoryImpl(this._local);
  final StatsLocalDataSource _local;

  @override
  Stream<Either<Failure, DashboardStats>> watchDashboard() =>
      ErrorHandler.guardStream(_local.watchDashboard());
}

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this._local);
  final SessionLocalDataSource _local;

  @override
  Future<Either<Failure, int?>> getCurrentUserId() =>
      ErrorHandler.guard(() async => _local.getCurrentUserId());

  @override
  Future<Either<Failure, Unit>> setCurrentUserId(int? id) =>
      ErrorHandler.guard(() async {
        await _local.setCurrentUserId(id);
        return unit;
      });
}

class DemoDataRepositoryImpl implements DemoDataRepository {
  DemoDataRepositoryImpl(this._local);
  final DemoLocalDataSource _local;

  Future<Either<Failure, Unit>> _run(Future<void> Function() action) =>
      ErrorHandler.guard(() async {
        await action();
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> seedDemo() => _run(_local.seedDemo);

  @override
  Future<Either<Failure, Unit>> seedLarge({
    int users = 1000,
    int projects = 100,
    int tasks = 10000,
  }) => _run(
    () => _local.seedLarge(users: users, projects: projects, tasks: tasks),
  );

  @override
  Future<Either<Failure, List<BenchmarkResult>>> runBenchmark() =>
      ErrorHandler.guard(_local.runBenchmark);

  @override
  Future<Either<Failure, int>> countTasks() =>
      ErrorHandler.guard(_local.countTasks);

  @override
  Future<Either<Failure, Unit>> clearAll() => _run(_local.clearAll);
}

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
