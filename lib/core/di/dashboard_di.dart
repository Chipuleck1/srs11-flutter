import 'package:get_it/get_it.dart';

import 'package:lab11/src/data/dashboard/datasources/stats_local_data_source.dart';
import 'package:lab11/src/data/dashboard/repositories/stats_repository_impl.dart';
import 'package:lab11/src/domain/dashboard/repositories/stats_repository.dart';
import 'package:lab11/src/domain/dashboard/usecases/watch_dashboard_usecase.dart';
import 'package:lab11/src/presentation/dashboard/bloc/dashboard_cubit.dart';

/// Фича «Статистика» (Dashboard).
void registerDashboardFeature(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => StatsLocalDataSource(getIt()))
    ..registerLazySingleton<StatsRepository>(() => StatsRepositoryImpl(getIt()))
    ..registerFactory(() => WatchDashboardUseCase(getIt()))
    ..registerFactory(() => DashboardCubit(getIt()));
}
