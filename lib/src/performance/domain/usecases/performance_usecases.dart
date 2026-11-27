import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/core/usecase/usecase.dart';
import 'package:lab11/src/performance/domain/entities/benchmark_result.dart';
import 'package:lab11/src/performance/domain/repositories/performance_repository.dart';

/// 1 000 пользователей, 100 проектов, 10 000 задач.
class GenerateLargeDataUseCase implements UseCase<Unit, NoParams> {
  GenerateLargeDataUseCase(this._repo);
  final PerformanceRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams _) =>
      _repo.seedLarge(users: 1000, projects: 100, tasks: 10000);
}

class RunBenchmarkUseCase implements UseCase<List<BenchmarkResult>, NoParams> {
  RunBenchmarkUseCase(this._repo);
  final PerformanceRepository _repo;

  @override
  Future<Either<Failure, List<BenchmarkResult>>> call(NoParams _) =>
      _repo.runBenchmark();
}

class CountTasksUseCase implements UseCase<int, NoParams> {
  CountTasksUseCase(this._repo);
  final PerformanceRepository _repo;

  @override
  Future<Either<Failure, int>> call(NoParams _) => _repo.countTasks();
}

class ClearAllDataUseCase implements UseCase<Unit, NoParams> {
  ClearAllDataUseCase(this._repo);
  final PerformanceRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams _) => _repo.clearAll();
}
