import 'package:fpdart/fpdart.dart' hide Task;

import '../../../core/error/failures.dart';
import '../entities/entities.dart';

abstract interface class StatsRepository {
  /// Статистика пересчитывается при любом изменении данных.
  Stream<Either<Failure, DashboardStats>> watchDashboard();
}
