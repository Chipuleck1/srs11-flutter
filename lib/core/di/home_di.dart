import 'package:get_it/get_it.dart';

import 'package:lab11/src/data/datasources/home/demo_seed_local_data_source.dart';
import 'package:lab11/src/data/datasources/home/session_local_data_source.dart';
import 'package:lab11/src/data/repositories/home/demo_seed_repository_impl.dart';
import 'package:lab11/src/data/repositories/home/session_repository_impl.dart';
import 'package:lab11/src/domain/repositories/home/demo_seed_repository.dart';
import 'package:lab11/src/domain/repositories/home/session_repository.dart';
import 'package:lab11/src/domain/usecases/home/seed_demo_data_usecase.dart';
import 'package:lab11/src/domain/usecases/home/session_usecases.dart';
import 'package:lab11/src/presentation/bloc/home/current_user_cubit.dart';
import 'package:lab11/src/presentation/bloc/home/welcome_cubit.dart';

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
    ..registerFactory(() => GetCurrentUserIdUseCase(getIt()))
    ..registerFactory(() => SetCurrentUserIdUseCase(getIt()))
    ..registerFactory(() => SeedDemoDataUseCase(getIt()))
    // presentation (текущий пользователь — один на всё приложение)
    ..registerLazySingleton(() => CurrentUserCubit(getIt(), getIt()))
    ..registerFactory(() => WelcomeCubit(getIt()));
}
