import 'package:get_it/get_it.dart';

import 'package:lab11/src/data/datasources/server_import/import_local_data_source.dart';
import 'package:lab11/src/data/datasources/server_import/import_remote_data_source.dart';
import 'package:lab11/src/data/repositories/server_import/import_repository_impl.dart';
import 'package:lab11/src/domain/repositories/server_import/import_repository.dart';
import 'package:lab11/src/domain/usecases/server_import/import_from_server_usecase.dart';
import 'package:lab11/src/presentation/bloc/server_import/import_cubit.dart';

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
