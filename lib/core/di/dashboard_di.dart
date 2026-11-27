import 'package:get_it/get_it.dart';

import 'package:lab11/src/data/datasources/dashboard/stats_local_data_source.dart';
import 'package:lab11/src/data/repositories/dashboard/stats_repository_impl.dart';
import 'package:lab11/src/domain/repositories/dashboard/stats_repository.dart';
import 'package:lab11/src/domain/usecases/dashboard/watch_dashboard_usecase.dart';
import 'package:lab11/src/presentation/bloc/dashboard/dashboard_cubit.dart';

/// Фича «Статистика» (Dashboard).
void registerDashboardFeature(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => StatsLocalDataSource(getIt()))
    ..registerLazySingleton<StatsRepository>(() => StatsRepositoryImpl(getIt()))
    ..registerFactory(() => WatchDashboardUseCase(getIt()))
    ..registerFactory(() => DashboardCubit(getIt()));
}
