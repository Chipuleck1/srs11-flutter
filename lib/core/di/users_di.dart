import 'package:get_it/get_it.dart';

import 'package:lab11/src/data/users/datasources/user_local_data_source.dart';
import 'package:lab11/src/data/users/repositories/user_repository_impl.dart';
import 'package:lab11/src/domain/users/repositories/user_repository.dart';
import 'package:lab11/src/domain/users/usecases/user_usecases.dart';
import 'package:lab11/src/presentation/users/bloc/user_detail_cubit.dart';
import 'package:lab11/src/presentation/users/bloc/user_picker_cubit.dart';
import 'package:lab11/src/presentation/users/bloc/users_cubit.dart';

/// Фича «Пользователи»: DataSource → Repository → UseCase → Cubit.
void registerUsersFeature(GetIt getIt) {
  getIt
    // data
    ..registerLazySingleton(() => UserLocalDataSource(getIt()))
    ..registerLazySingleton<UserRepository>(() => UserRepositoryImpl(getIt()))
    // domain
    ..registerFactory(() => WatchUsersUseCase(getIt()))
    ..registerFactory(() => WatchUserUseCase(getIt()))
    ..registerFactory(() => GetUserUseCase(getIt()))
    ..registerFactory(() => CreateUserUseCase(getIt()))
    ..registerFactory(() => UpdateUserUseCase(getIt()))
    ..registerFactory(() => DeleteUserUseCase(getIt()))
    // presentation
    ..registerFactory(() => UsersCubit(getIt(), getIt(), getIt(), getIt()))
    ..registerFactoryParam<UserDetailCubit, int, void>(
      (id, _) => UserDetailCubit(id, getIt()),
    )
    ..registerFactoryParam<UserPickerCubit, int?, int?>(
      (projectId, excludeProjectId) => UserPickerCubit(
        getIt(),
        getIt(),
        projectId: projectId,
        excludeProjectId: excludeProjectId,
      ),
    );
}
