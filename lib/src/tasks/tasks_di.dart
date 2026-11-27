import 'package:get_it/get_it.dart';

import 'package:lab11/src/tasks/data/datasources/comment_local_data_source.dart';
import 'package:lab11/src/tasks/data/datasources/task_local_data_source.dart';
import 'package:lab11/src/tasks/data/repositories/comment_repository_impl.dart';
import 'package:lab11/src/tasks/data/repositories/task_repository_impl.dart';
import 'package:lab11/src/tasks/domain/repositories/comment_repository.dart';
import 'package:lab11/src/tasks/domain/repositories/task_repository.dart';
import 'package:lab11/src/tasks/domain/usecases/comment_usecases.dart';
import 'package:lab11/src/tasks/domain/usecases/task_usecases.dart';
import 'package:lab11/src/tasks/presentation/bloc/comments_cubit.dart';
import 'package:lab11/src/tasks/presentation/bloc/task_detail_cubit.dart';
import 'package:lab11/src/tasks/presentation/bloc/task_form_cubit.dart';
import 'package:lab11/src/tasks/presentation/bloc/task_list_cubit.dart';

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
