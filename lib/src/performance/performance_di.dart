import 'package:get_it/get_it.dart';

import 'package:lab11/src/performance/data/datasources/performance_local_data_source.dart';
import 'package:lab11/src/performance/data/repositories/performance_repository_impl.dart';
import 'package:lab11/src/performance/domain/repositories/performance_repository.dart';
import 'package:lab11/src/performance/domain/usecases/performance_usecases.dart';
import 'package:lab11/src/performance/presentation/bloc/performance_cubit.dart';

/// Фича «Производительность»: 1000/100/10000 записей и сравнение индексов.
void registerPerformanceFeature(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => PerformanceLocalDataSource(getIt()))
    ..registerLazySingleton<PerformanceRepository>(
      () => PerformanceRepositoryImpl(getIt()),
    )
    ..registerFactory(() => GenerateLargeDataUseCase(getIt()))
    ..registerFactory(() => RunBenchmarkUseCase(getIt()))
    ..registerFactory(() => CountTasksUseCase(getIt()))
    ..registerFactory(() => ClearAllDataUseCase(getIt()))
    ..registerFactory(
      () => PerformanceCubit(getIt(), getIt(), getIt(), getIt()),
    );
}
