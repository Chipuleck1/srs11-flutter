import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/domain/entities/dashboard/dashboard_stats.dart';

abstract interface class StatsRepository {
  /// Статистика пересчитывается при любом изменении данных.
  Stream<Either<Failure, DashboardStats>> watchDashboard();
}
