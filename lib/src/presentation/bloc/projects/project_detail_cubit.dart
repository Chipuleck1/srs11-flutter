import 'dart:async';

import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/domain/entities/projects/project.dart';
import 'package:lab11/src/domain/usecases/projects/project_usecases.dart';

class ProjectDetailCubit extends WatchCubit<Project?> {
  ProjectDetailCubit(this.projectId, this._watch) {
    load();
  }
  final int projectId;
  final WatchProjectUseCase _watch;

  @override
  Stream<Either<Failure, Project?>> source() => _watch(projectId);
}
