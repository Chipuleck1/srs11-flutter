import 'package:fpdart/fpdart.dart' hide Task;

import '../../../core/error/error_handler.dart';
import '../../../core/error/failures.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_local_data_source.dart';
import '../mapper/mappers.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  ProjectRepositoryImpl(this._local);
  final ProjectLocalDataSource _local;

  Future<Either<Failure, Unit>> _run(Future<void> Function() action) =>
      ErrorHandler.guard(() async {
        await action();
        return unit;
      });

  @override
  Stream<Either<Failure, List<ProjectSummary>>> watchProjects() =>
      ErrorHandler.guardStream(
        _local.watchProjects().map(
          (rows) => [
            for (final r in rows)
              ProjectSummary(
                project: r.project.toEntity(),
                totalTasks: r.total,
                doneTasks: r.done,
                membersCount: r.members,
              ),
          ],
        ),
      );

  @override
  Stream<Either<Failure, Project?>> watchProject(int id) =>
      ErrorHandler.guardStream(
        _local.watchProject(id).map((r) => r?.toEntity()),
      );

  @override
  Future<Either<Failure, List<Project>>> getProjects() => ErrorHandler.guard(
    () async => (await _local.getProjects()).map((r) => r.toEntity()).toList(),
  );

  @override
  Future<Either<Failure, Project?>> getProject(int id) =>
      ErrorHandler.guard(() async => (await _local.getProject(id))?.toEntity());

  @override
  Future<Either<Failure, int>> createProject({
    required String name,
    required String description,
    required ProjectStatus status,
    DateTime? endDate,
    int? ownerId,
  }) => ErrorHandler.guard(
    () => _local.insert(
      name: name,
      description: description,
      status: status,
      endDate: endDate,
      ownerId: ownerId,
    ),
  );

  @override
  Future<Either<Failure, Unit>> updateProject(
    int id, {
    required String name,
    required String description,
    required ProjectStatus status,
    DateTime? endDate,
  }) => _run(
    () => _local.update(
      id,
      name: name,
      description: description,
      status: status,
      endDate: endDate,
    ),
  );

  @override
  Future<Either<Failure, Unit>> deleteProject(int id) =>
      _run(() => _local.delete(id));

  @override
  Stream<Either<Failure, List<ProjectMember>>> watchMembers(int projectId) =>
      ErrorHandler.guardStream(
        _local
            .watchMembers(projectId)
            .map(
              (rows) =>
                  [
                    for (final r in rows)
                      ProjectMember(user: r.user.toEntity(), role: r.role),
                  ]..sort(
                    (a, b) => a.role.index.compareTo(b.role.index),
                  ), // Owner -> Admin -> Member
            ),
      );

  @override
  Future<Either<Failure, List<User>>> getMembers(int projectId) =>
      ErrorHandler.guard(
        () async =>
            (await _local.getMembers(projectId))
                .map((r) => r.toEntity())
                .toList(),
      );

  @override
  Stream<Either<Failure, List<Project>>> watchProjectsOfUser(int userId) =>
      ErrorHandler.guardStream(
        _local
            .watchProjectsOfUser(userId)
            .map((rows) => rows.map((r) => r.toEntity()).toList()),
      );

  @override
  Future<Either<Failure, bool>> isMember(int projectId, int userId) =>
      ErrorHandler.guard(() => _local.isMember(projectId, userId));

  @override
  Future<Either<Failure, Unit>> addMember(
    int projectId,
    int userId,
    MemberRole role,
  ) => _run(() => _local.addMember(projectId, userId, role));

  @override
  Future<Either<Failure, Unit>> changeRole(
    int projectId,
    int userId,
    MemberRole role,
  ) => _run(() => _local.changeRole(projectId, userId, role));

  @override
  Future<Either<Failure, Unit>> removeMember(int projectId, int userId) =>
      _run(() => _local.removeMember(projectId, userId));
}
