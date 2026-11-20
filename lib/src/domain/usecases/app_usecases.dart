import 'package:fpdart/fpdart.dart' hide Task;

import '../../../core/error/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../entities/entities.dart';
import '../repositories/demo_data_repository.dart';
import '../repositories/import_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/stats_repository.dart';

// ---------------- статистика ----------------

class WatchDashboardUseCase implements StreamUseCase<DashboardStats, NoParams> {
  WatchDashboardUseCase(this._repo);
  final StatsRepository _repo;

  @override
  Stream<Either<Failure, DashboardStats>> call(NoParams _) =>
      _repo.watchDashboard();
}

// ---------------- текущий пользователь ----------------

class GetCurrentUserIdUseCase implements UseCase<int?, NoParams> {
  GetCurrentUserIdUseCase(this._repo);
  final SessionRepository _repo;

  @override
  Future<Either<Failure, int?>> call(NoParams _) => _repo.getCurrentUserId();
}

class SetCurrentUserIdUseCase implements UseCase<Unit, int?> {
  SetCurrentUserIdUseCase(this._repo);
  final SessionRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(int? id) => _repo.setCurrentUserId(id);
}

// ---------------- тестовые данные ----------------

class SeedDemoDataUseCase implements UseCase<Unit, NoParams> {
  SeedDemoDataUseCase(this._repo);
  final DemoDataRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams _) => _repo.seedDemo();
}

/// 1 000 пользователей, 100 проектов, 10 000 задач.
class GenerateLargeDataUseCase implements UseCase<Unit, NoParams> {
  GenerateLargeDataUseCase(this._repo);
  final DemoDataRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams _) =>
      _repo.seedLarge(users: 1000, projects: 100, tasks: 10000);
}

class RunBenchmarkUseCase implements UseCase<List<BenchmarkResult>, NoParams> {
  RunBenchmarkUseCase(this._repo);
  final DemoDataRepository _repo;

  @override
  Future<Either<Failure, List<BenchmarkResult>>> call(NoParams _) =>
      _repo.runBenchmark();
}

class CountTasksUseCase implements UseCase<int, NoParams> {
  CountTasksUseCase(this._repo);
  final DemoDataRepository _repo;

  @override
  Future<Either<Failure, int>> call(NoParams _) => _repo.countTasks();
}

class ClearAllDataUseCase implements UseCase<Unit, NoParams> {
  ClearAllDataUseCase(this._repo);
  final DemoDataRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams _) => _repo.clearAll();
}

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
