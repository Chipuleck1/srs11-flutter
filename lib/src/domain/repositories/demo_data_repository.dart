import 'package:fpdart/fpdart.dart' hide Task;

import '../../../core/error/failures.dart';
import '../entities/entities.dart';

/// Тестовые данные и проверка производительности.
abstract interface class DemoDataRepository {
  Future<Either<Failure, Unit>> seedDemo();
  Future<Either<Failure, Unit>> seedLarge({int users, int projects, int tasks});
  Future<Either<Failure, List<BenchmarkResult>>> runBenchmark();
  Future<Either<Failure, int>> countTasks();
  Future<Either<Failure, Unit>> clearAll();
}
