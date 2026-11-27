import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/core/usecase/usecase.dart';
import 'package:lab11/src/domain/entities/projects/project.dart';
import 'package:lab11/src/domain/usecases/projects/project_usecases.dart';
import 'package:lab11/src/domain/entities/tasks/task.dart';
import 'package:lab11/src/domain/usecases/tasks/task_usecases.dart';
import 'package:lab11/src/domain/entities/users/user.dart';

/// Форма задачи: справочники (проекты, участники) + отправка.
class TaskFormState {
  const TaskFormState({
    this.projects = const [],
    this.members = const [],
    this.submitting = false,
  });

  final List<Project> projects;
  final List<User> members;
  final bool submitting;

  TaskFormState copyWith({
    List<Project>? projects,
    List<User>? members,
    bool? submitting,
  }) => TaskFormState(
    projects: projects ?? this.projects,
    members: members ?? this.members,
    submitting: submitting ?? this.submitting,
  );
}

class TaskFormCubit extends Cubit<TaskFormState> {
  TaskFormCubit(
    this._projects,
    this._members,
    this._create,
    this._update,
    this._reassign,
  ) : super(const TaskFormState());

  final GetProjectsUseCase _projects;
  final GetProjectMembersUseCase _members;
  final CreateTaskUseCase _create;
  final UpdateTaskUseCase _update;
  final ReassignTaskUseCase _reassign;

  Future<void> init(int? projectId) async {
    final p = (await _projects(const NoParams())).getOrElse((_) => []);
    if (!isClosed) emit(state.copyWith(projects: p));
    await loadMembers(projectId);
  }

  Future<void> loadMembers(int? projectId) async {
    final m = projectId == null
        ? <User>[]
        : (await _members(projectId)).getOrElse((_) => []);
    if (!isClosed) emit(state.copyWith(members: m));
  }

  /// Защита от двойного нажатия: пока идёт сохранение, новый запрос не отправляется.
  Future<Failure?> submit({
    required Task? existing,
    required TaskDraft draft,
    required int? actorId,
  }) async {
    if (state.submitting) return null;
    emit(state.copyWith(submitting: true));
    final Either<Failure, Object?> result;
    if (existing == null) {
      result = await _create((draft: draft, actorId: actorId));
    } else {
      final updated = await _update((
        id: existing.id,
        title: draft.title,
        description: draft.description,
        priority: draft.priority,
        deadline: draft.deadline,
      ));
      result = updated.isLeft() || draft.assigneeId == existing.assigneeId
          ? updated
          : await _reassign((
              id: existing.id,
              assigneeId: draft.assigneeId,
              actorId: actorId,
            ));
    }
    if (!isClosed) emit(state.copyWith(submitting: false));
    return result.fold((f) => f, (_) => null);
  }
}
