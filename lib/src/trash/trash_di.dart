import 'package:get_it/get_it.dart';

import 'package:lab11/src/trash/data/datasources/trash_local_data_source.dart';
import 'package:lab11/src/trash/data/repositories/trash_repository_impl.dart';
import 'package:lab11/src/trash/domain/repositories/trash_repository.dart';
import 'package:lab11/src/trash/domain/usecases/trash_usecases.dart';
import 'package:lab11/src/trash/presentation/bloc/trash_cubit.dart';

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
