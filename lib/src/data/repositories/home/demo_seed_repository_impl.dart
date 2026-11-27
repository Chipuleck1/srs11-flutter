import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/error_handler.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/data/datasources/home/demo_seed_local_data_source.dart';
import 'package:lab11/src/domain/repositories/home/demo_seed_repository.dart';

class DemoSeedRepositoryImpl implements DemoSeedRepository {
  DemoSeedRepositoryImpl(this._local);
  final DemoSeedLocalDataSource _local;

  @override
  Future<Either<Failure, Unit>> seedDemo() => ErrorHandler.guard(() async {
    await _local.seedDemo();
    return unit;
  });
}
