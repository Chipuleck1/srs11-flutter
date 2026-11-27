import 'package:get_it/get_it.dart';

import 'package:lab11/src/data/home/datasources/demo_seed_local_data_source.dart';
import 'package:lab11/src/data/home/datasources/session_local_data_source.dart';
import 'package:lab11/src/data/home/repositories/demo_seed_repository_impl.dart';
import 'package:lab11/src/data/home/repositories/session_repository_impl.dart';
import 'package:lab11/src/domain/home/repositories/demo_seed_repository.dart';
import 'package:lab11/src/domain/home/repositories/session_repository.dart';
import 'package:lab11/src/domain/home/usecases/seed_demo_data_usecase.dart';
import 'package:lab11/src/domain/home/usecases/session_usecases.dart';
import 'package:lab11/src/presentation/home/bloc/current_user_cubit.dart';
import 'package:lab11/src/presentation/home/bloc/welcome_cubit.dart';

/// Фича «Главная»: текущий пользователь, приветственный экран и демо-данные.
void registerHomeFeature(GetIt getIt) {
  getIt
    // data
    ..registerLazySingleton(() => SessionLocalDataSource(getIt()))
    ..registerLazySingleton(() => DemoSeedLocalDataSource(getIt()))
    ..registerLazySingleton<SessionRepository>(
      () => SessionRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<DemoSeedRepository>(
      () => DemoSeedRepositoryImpl(getIt()),
    )
    // domain
    ..registerFactory(() => GetSessionUseCase(getIt()))
    ..registerFactory(() => SetCurrentUserIdUseCase(getIt()))
    ..registerFactory(() => SeedDemoDataUseCase(getIt()))
    // presentation (текущий пользователь — один на всё приложение)
    ..registerLazySingleton(() => CurrentUserCubit(getIt(), getIt()))
    ..registerFactory(() => WelcomeCubit(getIt()));
}
