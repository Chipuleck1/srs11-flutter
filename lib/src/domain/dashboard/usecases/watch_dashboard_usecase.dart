import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/core/usecase/usecase.dart';
import 'package:lab11/src/domain/dashboard/entities/dashboard_stats.dart';
import 'package:lab11/src/domain/dashboard/repositories/stats_repository.dart';

class WatchDashboardUseCase implements StreamUseCase<DashboardStats, NoParams> {
  WatchDashboardUseCase(this._repo);
  final StatsRepository _repo;

  @override
  Stream<Either<Failure, DashboardStats>> call(NoParams _) =>
      _repo.watchDashboard();
}
