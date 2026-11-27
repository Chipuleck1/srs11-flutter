import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/performance/domain/entities/benchmark_result.dart';

/// Большая тестовая база и проверка производительности.
abstract interface class PerformanceRepository {
  Future<Either<Failure, Unit>> seedLarge({int users, int projects, int tasks});
  Future<Either<Failure, List<BenchmarkResult>>> runBenchmark();
  Future<Either<Failure, int>> countTasks();
  Future<Either<Failure, Unit>> clearAll();
}
