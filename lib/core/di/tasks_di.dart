import 'package:get_it/get_it.dart';

import 'package:lab11/src/data/datasources/tasks/comment_local_data_source.dart';
import 'package:lab11/src/data/datasources/tasks/task_local_data_source.dart';
import 'package:lab11/src/data/repositories/tasks/comment_repository_impl.dart';
import 'package:lab11/src/data/repositories/tasks/task_repository_impl.dart';
import 'package:lab11/src/domain/repositories/tasks/comment_repository.dart';
import 'package:lab11/src/domain/repositories/tasks/task_repository.dart';
import 'package:lab11/src/domain/usecases/tasks/comment_usecases.dart';
import 'package:lab11/src/domain/usecases/tasks/task_usecases.dart';
import 'package:lab11/src/presentation/bloc/tasks/comments_cubit.dart';
import 'package:lab11/src/presentation/bloc/tasks/task_detail_cubit.dart';
import 'package:lab11/src/presentation/bloc/tasks/task_form_cubit.dart';
import 'package:lab11/src/presentation/bloc/tasks/task_list_cubit.dart';

/// Фича «Задачи»: задачи, история, комментарии и вложения.
void registerTasksFeature(GetIt getIt) {
  getIt
    // data
    ..registerLazySingleton(() => TaskLocalDataSource(getIt()))
    ..registerLazySingleton(() => CommentLocalDataSource(getIt()))
    ..registerLazySingleton<TaskRepository>(() => TaskRepositoryImpl(getIt()))
    ..registerLazySingleton<CommentRepository>(
      () => CommentRepositoryImpl(getIt()),
    )
    // domain: задачи
    ..registerFactory(() => WatchTasksUseCase(getIt()))
    ..registerFactory(() => WatchTaskCountUseCase(getIt()))
    ..registerFactory(() => WatchTaskUseCase(getIt()))
    ..registerFactory(() => WatchTaskHistoryUseCase(getIt()))
    ..registerFactory(() => CreateTaskUseCase(getIt(), getIt()))
    ..registerFactory(() => UpdateTaskUseCase(getIt()))
    ..registerFactory(() => ChangeTaskPriorityUseCase(getIt()))
    ..registerFactory(() => ChangeTaskStatusUseCase(getIt()))
    ..registerFactory(() => ReassignTaskUseCase(getIt(), getIt()))
    ..registerFactory(() => UndoStatusChangeUseCase(getIt()))
    ..registerFactory(() => CanUndoStatusChangeUseCase(getIt()))
    ..registerFactory(() => MoveTaskToTrashUseCase(getIt()))
    // domain: комментарии и вложения
    ..registerFactory(() => WatchCommentsUseCase(getIt()))
    ..registerFactory(() => AddCommentUseCase(getIt(), getIt()))
    ..registerFactory(() => DeleteCommentUseCase(getIt()))
    ..registerFactory(() => WatchAttachmentsUseCase(getIt()))
    ..registerFactory(() => AddAttachmentUseCase(getIt(), getIt()))
    ..registerFactory(() => DeleteAttachmentUseCase(getIt()))
    // presentation
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
    );
}
