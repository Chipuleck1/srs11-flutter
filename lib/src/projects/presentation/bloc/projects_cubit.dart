import 'dart:async';

import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/core/usecase/usecase.dart';
import 'package:lab11/src/projects/domain/entities/project.dart';
import 'package:lab11/src/projects/domain/usecases/project_usecases.dart';

// ---------------- проекты ----------------

class ProjectsCubit extends WatchCubit<List<ProjectSummary>> {
  ProjectsCubit(this._watch, this._create, this._update, this._delete) {
    load();
  }
  final WatchProjectsUseCase _watch;
  final CreateProjectUseCase _create;
  final UpdateProjectUseCase _update;
  final DeleteProjectUseCase _delete;

  @override
  Stream<Either<Failure, List<ProjectSummary>>> source() =>
      _watch(const NoParams());

  Future<Failure?> create(ProjectParams data, {int? ownerId}) =>
      act(_create((data: data, ownerId: ownerId)));
  Future<Failure?> update(int id, ProjectParams data) =>
      act(_update((id: id, data: data)));
  Future<Failure?> delete(int id) => act(_delete(id));
}
