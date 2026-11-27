import 'dart:async';

import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/models/enums.dart';
import 'package:lab11/src/domain/projects/entities/project.dart';
import 'package:lab11/src/domain/projects/usecases/project_usecases.dart';

class MembersCubit extends WatchCubit<List<ProjectMember>> {
  MembersCubit(
    this.projectId,
    this._watch,
    this._add,
    this._role,
    this._remove,
  ) {
    load();
  }
  final int projectId;
  final WatchMembersUseCase _watch;
  final AddMemberUseCase _add;
  final ChangeMemberRoleUseCase _role;
  final RemoveMemberUseCase _remove;

  @override
  Stream<Either<Failure, List<ProjectMember>>> source() => _watch(projectId);

  Future<Failure?> add(int userId, MemberRole role) =>
      act(_add((projectId: projectId, userId: userId, role: role)));
  Future<Failure?> changeRole(int userId, MemberRole role) =>
      act(_role((projectId: projectId, userId: userId, role: role)));
  Future<Failure?> remove(int userId) =>
      act(_remove((projectId: projectId, userId: userId)));
}
