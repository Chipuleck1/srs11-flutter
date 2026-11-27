import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/error_handler.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/performance/data/datasources/performance_local_data_source.dart';
import 'package:lab11/src/performance/domain/entities/benchmark_result.dart';
import 'package:lab11/src/performance/domain/repositories/performance_repository.dart';

class PerformanceRepositoryImpl implements PerformanceRepository {
  PerformanceRepositoryImpl(this._local);
  final PerformanceLocalDataSource _local;

  Future<Either<Failure, Unit>> _run(Future<void> Function() action) =>
      ErrorHandler.guard(() async {
        await action();
        return unit;
      });

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
