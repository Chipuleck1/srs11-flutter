import 'package:dio/dio.dart' show HttpClientAdapter;
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../src/data/datasources/comment_local_data_source.dart';
import '../../src/data/datasources/demo_local_data_source.dart';
import '../../src/data/datasources/import_local_data_source.dart';
import '../../src/data/datasources/import_remote_data_source.dart';
import '../../src/data/datasources/project_local_data_source.dart';
import '../../src/data/datasources/session_local_data_source.dart';
import '../../src/data/datasources/stats_local_data_source.dart';
import '../../src/data/datasources/task_local_data_source.dart';
import '../../src/data/datasources/user_local_data_source.dart';
import '../../src/data/repositories/app_repositories_impl.dart';
import '../../src/data/repositories/comment_repository_impl.dart';
import '../../src/data/repositories/project_repository_impl.dart';
import '../../src/data/repositories/task_repository_impl.dart';
import '../../src/data/repositories/user_repository_impl.dart';
import '../../src/domain/repositories/comment_repository.dart';
import '../../src/domain/repositories/demo_data_repository.dart';
import '../../src/domain/repositories/import_repository.dart';
import '../../src/domain/repositories/project_repository.dart';
import '../../src/domain/repositories/session_repository.dart';
import '../../src/domain/repositories/stats_repository.dart';
import '../../src/domain/repositories/task_repository.dart';
import '../../src/domain/repositories/user_repository.dart';
import '../../src/domain/usecases/app_usecases.dart';
import '../../src/domain/usecases/comment_usecases.dart';
import '../../src/domain/usecases/project_usecases.dart';
import '../../src/domain/usecases/task_usecases.dart';
import '../../src/domain/usecases/user_usecases.dart';
import '../../src/presentation/bloc/cubits.dart';
import '../../src/presentation/bloc/import_cubit.dart';
import '../database/app_database.dart';
import '../rest_client/rest_client.dart';

final getIt = GetIt.instance;

/// Регистрация всех зависимостей в одном месте.
/// Порядок: внешние сервисы → DataSource → Repository → UseCase → Cubit.
/// [executor], [prefs], [httpAdapter] подменяются в тестах.
Future<void> configureDependencies({
  QueryExecutor? executor,
  SharedPreferences? prefs,
  HttpClientAdapter? httpAdapter,
}) async {
  // 1. Внешние сервисы (одни на всё приложение)
  getIt
    ..registerLazySingleton<AppDatabase>(
      () => AppDatabase(executor),
      dispose: (db) => db.close(),
    )
    ..registerSingleton<SharedPreferences>(
      prefs ?? await SharedPreferences.getInstance(),
    )
    ..registerLazySingleton<RestClient>(() => RestClient(adapter: httpAdapter));

  // 2. DataSource
  getIt
    ..registerLazySingleton(() => UserLocalDataSource(getIt()))
    ..registerLazySingleton(() => ProjectLocalDataSource(getIt()))
    ..registerLazySingleton(() => TaskLocalDataSource(getIt()))
    ..registerLazySingleton(() => CommentLocalDataSource(getIt()))
    ..registerLazySingleton(() => StatsLocalDataSource(getIt()))
    ..registerLazySingleton(() => DemoLocalDataSource(getIt()))
    ..registerLazySingleton(() => SessionLocalDataSource(getIt()))
    ..registerLazySingleton(() => ImportLocalDataSource(getIt()))
    ..registerLazySingleton<ImportRemoteDataSource>(
      () => ImportRemoteDataSourceImpl(getIt()),
    );

  // 3. Repository: в Domain регистрируется абстракция, реализация — из Data
  getIt
    ..registerLazySingleton<UserRepository>(() => UserRepositoryImpl(getIt()))
    ..registerLazySingleton<ProjectRepository>(
      () => ProjectRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<TaskRepository>(() => TaskRepositoryImpl(getIt()))
    ..registerLazySingleton<CommentRepository>(
      () => CommentRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<StatsRepository>(() => StatsRepositoryImpl(getIt()))
    ..registerLazySingleton<SessionRepository>(
      () => SessionRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<DemoDataRepository>(
      () => DemoDataRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<ImportRepository>(
      () => ImportRepositoryImpl(getIt(), getIt()),
    );

  // 4. UseCase (лёгкие объекты — factory)
  getIt
    // пользователи
    ..registerFactory(() => WatchUsersUseCase(getIt()))
    ..registerFactory(() => WatchUserUseCase(getIt()))
    ..registerFactory(() => GetUserUseCase(getIt()))
    ..registerFactory(() => CreateUserUseCase(getIt()))
    ..registerFactory(() => UpdateUserUseCase(getIt()))
    ..registerFactory(() => DeleteUserUseCase(getIt()))
    // проекты
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
    // задачи
    ..registerFactory(() => WatchTasksUseCase(getIt()))
    ..registerFactory(() => WatchTaskCountUseCase(getIt()))
    ..registerFactory(() => WatchTaskUseCase(getIt()))
    ..registerFactory(() => WatchTaskHistoryUseCase(getIt()))
    ..registerFactory(() => WatchTrashUseCase(getIt()))
    ..registerFactory(() => CreateTaskUseCase(getIt(), getIt()))
    ..registerFactory(() => UpdateTaskUseCase(getIt()))
    ..registerFactory(() => ChangeTaskPriorityUseCase(getIt()))
    ..registerFactory(() => ChangeTaskStatusUseCase(getIt()))
    ..registerFactory(() => ReassignTaskUseCase(getIt(), getIt()))
    ..registerFactory(() => UndoStatusChangeUseCase(getIt()))
    ..registerFactory(() => CanUndoStatusChangeUseCase(getIt()))
    ..registerFactory(() => MoveTaskToTrashUseCase(getIt()))
    ..registerFactory(() => RestoreTaskUseCase(getIt()))
    ..registerFactory(() => DeleteTaskForeverUseCase(getIt()))
    ..registerFactory(() => EmptyTrashUseCase(getIt()))
    // комментарии и вложения
    ..registerFactory(() => WatchCommentsUseCase(getIt()))
    ..registerFactory(() => AddCommentUseCase(getIt(), getIt()))
    ..registerFactory(() => DeleteCommentUseCase(getIt()))
    ..registerFactory(() => WatchAttachmentsUseCase(getIt()))
    ..registerFactory(() => AddAttachmentUseCase(getIt(), getIt()))
    ..registerFactory(() => DeleteAttachmentUseCase(getIt()))
    // приложение
    ..registerFactory(() => WatchDashboardUseCase(getIt()))
    ..registerFactory(() => GetCurrentUserIdUseCase(getIt()))
    ..registerFactory(() => SetCurrentUserIdUseCase(getIt()))
    ..registerFactory(() => SeedDemoDataUseCase(getIt()))
    ..registerFactory(() => GenerateLargeDataUseCase(getIt()))
    ..registerFactory(() => RunBenchmarkUseCase(getIt()))
    ..registerFactory(() => CountTasksUseCase(getIt()))
    ..registerFactory(() => ClearAllDataUseCase(getIt()))
    ..registerFactory(() => ImportFromServerUseCase(getIt()));

  // 5. Cubit (новый экземпляр на каждый экран; с параметром — registerFactoryParam)
  getIt
    ..registerLazySingleton(() => CurrentUserCubit(getIt(), getIt()))
    ..registerFactory(() => DashboardCubit(getIt()))
    ..registerFactory(() => ProjectsCubit(getIt(), getIt(), getIt(), getIt()))
    ..registerFactoryParam<ProjectDetailCubit, int, void>(
      (id, _) => ProjectDetailCubit(id, getIt()),
    )
    ..registerFactoryParam<MembersCubit, int, void>(
      (id, _) => MembersCubit(id, getIt(), getIt(), getIt(), getIt()),
    )
    ..registerFactoryParam<TaskListCubit, int?, int?>(
      (projectId, assigneeId) => TaskListCubit(
        getIt(),
        getIt(),
        projectId: projectId,
        assigneeId: assigneeId,
      ),
    )
    ..registerFactoryParam<TaskDetailCubit, int, void>(
      (id, _) => TaskDetailCubit(
        id,
        getIt(),
        getIt(),
        getIt(),
        getIt(),
        getIt(),
        getIt(),
        getIt(),
      ),
    )
    ..registerFactoryParam<CommentsCubit, int, void>(
      (id, _) => CommentsCubit(id, getIt(), getIt(), getIt()),
    )
    ..registerFactoryParam<AttachmentsCubit, int, void>(
      (id, _) => AttachmentsCubit(id, getIt(), getIt(), getIt()),
    )
    ..registerFactory(
      () => TaskFormCubit(getIt(), getIt(), getIt(), getIt(), getIt()),
    )
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
    )
    ..registerFactory(() => TrashCubit(getIt(), getIt(), getIt(), getIt()))
    ..registerFactory(
      () => PerformanceCubit(getIt(), getIt(), getIt(), getIt()),
    )
    ..registerFactory(() => WelcomeCubit(getIt()))
    ..registerFactory(() => ImportCubit(getIt()));
}
