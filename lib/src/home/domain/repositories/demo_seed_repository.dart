import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';

/// Заполнение пустой базы демо-данными (первый запуск).
abstract interface class DemoSeedRepository {
  Future<Either<Failure, Unit>> seedDemo();
}
