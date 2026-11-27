import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/error_handler.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/data/dashboard/datasources/stats_local_data_source.dart';
import 'package:lab11/src/domain/dashboard/entities/dashboard_stats.dart';
import 'package:lab11/src/domain/dashboard/repositories/stats_repository.dart';

class StatsRepositoryImpl implements StatsRepository {
  StatsRepositoryImpl(this._local);
  final StatsLocalDataSource _local;

  @override
  Stream<Either<Failure, DashboardStats>> watchDashboard() =>
      ErrorHandler.guardStream(_local.watchDashboard());
}
