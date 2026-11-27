import 'package:get_it/get_it.dart';

import 'package:lab11/src/dashboard/data/datasources/stats_local_data_source.dart';
import 'package:lab11/src/dashboard/data/repositories/stats_repository_impl.dart';
import 'package:lab11/src/dashboard/domain/repositories/stats_repository.dart';
import 'package:lab11/src/dashboard/domain/usecases/watch_dashboard_usecase.dart';
import 'package:lab11/src/dashboard/presentation/bloc/dashboard_cubit.dart';

/// Фича «Статистика» (Dashboard).
void registerDashboardFeature(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => StatsLocalDataSource(getIt()))
    ..registerLazySingleton<StatsRepository>(() => StatsRepositoryImpl(getIt()))
    ..registerFactory(() => WatchDashboardUseCase(getIt()))
    ..registerFactory(() => DashboardCubit(getIt()));
}
