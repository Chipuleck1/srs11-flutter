import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/models/enums.dart';
import 'package:lab11/src/domain/entities/projects/project.dart';
import 'package:lab11/src/domain/entities/users/user.dart';

abstract interface class ProjectRepository {
  Stream<Either<Failure, List<ProjectSummary>>> watchProjects();
  Stream<Either<Failure, Project?>> watchProject(int id);
  Future<Either<Failure, List<Project>>> getProjects();
  Future<Either<Failure, Project?>> getProject(int id);

  /// Создатель проекта ([ownerId]) сразу становится Owner — атомарно.
  Future<Either<Failure, int>> createProject({
    required String name,
    required String description,
    required ProjectStatus status,
    DateTime? endDate,
    int? ownerId,
  });
  Future<Either<Failure, Unit>> updateProject(
    int id, {
    required String name,
    required String description,
    required ProjectStatus status,
    DateTime? endDate,
  });
  Future<Either<Failure, Unit>> deleteProject(int id);

  Stream<Either<Failure, List<ProjectMember>>> watchMembers(int projectId);
  Future<Either<Failure, List<User>>> getMembers(int projectId);
  Stream<Either<Failure, List<Project>>> watchProjectsOfUser(int userId);
  Future<Either<Failure, bool>> isMember(int projectId, int userId);
  Future<Either<Failure, Unit>> addMember(
    int projectId,
    int userId,
    MemberRole role,
  );
  Future<Either<Failure, Unit>> changeRole(
    int projectId,
    int userId,
    MemberRole role,
  );

  /// Исключает участника и снимает его с задач проекта — атомарно.
  Future<Either<Failure, Unit>> removeMember(int projectId, int userId);
}
