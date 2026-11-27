import 'package:get_it/get_it.dart';

import 'package:lab11/src/data/trash/datasources/trash_local_data_source.dart';
import 'package:lab11/src/data/trash/repositories/trash_repository_impl.dart';
import 'package:lab11/src/domain/trash/repositories/trash_repository.dart';
import 'package:lab11/src/domain/trash/usecases/trash_usecases.dart';
import 'package:lab11/src/presentation/trash/bloc/trash_cubit.dart';

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
