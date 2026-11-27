import 'package:get_it/get_it.dart';

import 'package:lab11/src/data/datasources/projects/project_local_data_source.dart';
import 'package:lab11/src/data/repositories/projects/project_repository_impl.dart';
import 'package:lab11/src/domain/repositories/projects/project_repository.dart';
import 'package:lab11/src/domain/usecases/projects/project_usecases.dart';
import 'package:lab11/src/presentation/bloc/projects/members_cubit.dart';
import 'package:lab11/src/presentation/bloc/projects/project_detail_cubit.dart';
import 'package:lab11/src/presentation/bloc/projects/projects_cubit.dart';

/// Фича «Проекты» и участники проектов.
void registerProjectsFeature(GetIt getIt) {
  getIt
    // data
    ..registerLazySingleton(() => ProjectLocalDataSource(getIt()))
    ..registerLazySingleton<ProjectRepository>(
      () => ProjectRepositoryImpl(getIt()),
    )
    // domain
    ..registerFactory(() => WatchProjectsUseCase(getIt()))
    ..registerFactory(() => WatchProjectUseCase(getIt()))
    ..registerFactory(() => GetProjectsUseCase(getIt()))
    ..registerFactory(() => CreateProjectUseCase(getIt()))
    ..registerFactory(() => UpdateProjectUseCase(getIt()))
    ..registerFactory(() => DeleteProjectUseCase(getIt()))
    ..registerFactory(() => WatchMembersUseCase(getIt()))
    ..registerFactory(() => GetProjectMembersUseCase(getIt()))
    ..registerFactory(() => WatchUserProjectsUseCase(getIt()))
    ..registerFactory(() => AddMemberUseCase(getIt()))
    ..registerFactory(() => ChangeMemberRoleUseCase(getIt()))
    ..registerFactory(() => RemoveMemberUseCase(getIt()))
    // presentation
    ..registerFactory(() => ProjectsCubit(getIt(), getIt(), getIt(), getIt()))
    ..registerFactoryParam<ProjectDetailCubit, int, void>(
      (id, _) => ProjectDetailCubit(id, getIt()),
    )
    ..registerFactoryParam<MembersCubit, int, void>(
      (id, _) => MembersCubit(id, getIt(), getIt(), getIt(), getIt()),
    );
}
