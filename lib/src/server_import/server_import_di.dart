import 'package:get_it/get_it.dart';

import 'package:lab11/src/server_import/data/datasources/import_local_data_source.dart';
import 'package:lab11/src/server_import/data/datasources/import_remote_data_source.dart';
import 'package:lab11/src/server_import/data/repositories/import_repository_impl.dart';
import 'package:lab11/src/server_import/domain/repositories/import_repository.dart';
import 'package:lab11/src/server_import/domain/usecases/import_from_server_usecase.dart';
import 'package:lab11/src/server_import/presentation/bloc/import_cubit.dart';

/// Новая фича «Импорт с сервера»: Remote + Local DataSource.
void registerServerImportFeature(GetIt getIt) {
  getIt
    ..registerLazySingleton<ImportRemoteDataSource>(
      () => ImportRemoteDataSourceImpl(getIt()),
    )
    ..registerLazySingleton(() => ImportLocalDataSource(getIt()))
    ..registerLazySingleton<ImportRepository>(
      () => ImportRepositoryImpl(getIt(), getIt()),
    )
    ..registerFactory(() => ImportFromServerUseCase(getIt()))
    ..registerFactory(() => ImportCubit(getIt()));
}
