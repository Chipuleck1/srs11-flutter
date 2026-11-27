import 'package:get_it/get_it.dart';

import 'package:lab11/src/data/server_import/datasources/import_local_data_source.dart';
import 'package:lab11/src/data/server_import/datasources/import_remote_data_source.dart';
import 'package:lab11/src/data/server_import/repositories/import_repository_impl.dart';
import 'package:lab11/src/domain/server_import/repositories/import_repository.dart';
import 'package:lab11/src/domain/server_import/usecases/import_from_server_usecase.dart';
import 'package:lab11/src/presentation/server_import/bloc/import_cubit.dart';

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
