import 'package:get_it/get_it.dart';

import 'package:lab11/src/data/datasources/trash/trash_local_data_source.dart';
import 'package:lab11/src/data/repositories/trash/trash_repository_impl.dart';
import 'package:lab11/src/domain/repositories/trash/trash_repository.dart';
import 'package:lab11/src/domain/usecases/trash/trash_usecases.dart';
import 'package:lab11/src/presentation/bloc/trash/trash_cubit.dart';

/// Фича «Корзина» (soft delete).
void registerTrashFeature(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => TrashLocalDataSource(getIt()))
    ..registerLazySingleton<TrashRepository>(() => TrashRepositoryImpl(getIt()))
    ..registerFactory(() => WatchTrashUseCase(getIt()))
    ..registerFactory(() => RestoreTaskUseCase(getIt()))
    ..registerFactory(() => DeleteTaskForeverUseCase(getIt()))
    ..registerFactory(() => EmptyTrashUseCase(getIt()))
    ..registerFactory(() => TrashCubit(getIt(), getIt(), getIt(), getIt()));
}
