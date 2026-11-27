import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/core/usecase/usecase.dart';
import 'package:lab11/src/home/domain/repositories/demo_seed_repository.dart';

// ---------------- тестовые данные ----------------

class SeedDemoDataUseCase implements UseCase<Unit, NoParams> {
  SeedDemoDataUseCase(this._repo);
  final DemoSeedRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams _) => _repo.seedDemo();
}
