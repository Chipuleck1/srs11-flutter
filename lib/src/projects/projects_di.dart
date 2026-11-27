import 'package:get_it/get_it.dart';

import 'package:lab11/src/projects/data/datasources/project_local_data_source.dart';
import 'package:lab11/src/projects/data/repositories/project_repository_impl.dart';
import 'package:lab11/src/projects/domain/repositories/project_repository.dart';
import 'package:lab11/src/projects/domain/usecases/project_usecases.dart';
import 'package:lab11/src/projects/presentation/bloc/members_cubit.dart';
import 'package:lab11/src/projects/presentation/bloc/project_detail_cubit.dart';
import 'package:lab11/src/projects/presentation/bloc/projects_cubit.dart';

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
