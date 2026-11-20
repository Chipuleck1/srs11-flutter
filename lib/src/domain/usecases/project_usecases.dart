import 'package:fpdart/fpdart.dart' hide Task;

import '../../../core/error/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../entities/entities.dart';
import '../repositories/project_repository.dart';
import 'validators.dart';

typedef ProjectParams = ({
  String name,
  String description,
  ProjectStatus status,
  DateTime? endDate,
});

class WatchProjectsUseCase
    implements StreamUseCase<List<ProjectSummary>, NoParams> {
  WatchProjectsUseCase(this._repo);
  final ProjectRepository _repo;

  @override
  Stream<Either<Failure, List<ProjectSummary>>> call(NoParams _) =>
      _repo.watchProjects();
}

class WatchProjectUseCase implements StreamUseCase<Project?, int> {
  WatchProjectUseCase(this._repo);
  final ProjectRepository _repo;

  @override
  Stream<Either<Failure, Project?>> call(int id) => _repo.watchProject(id);
}

class GetProjectsUseCase implements UseCase<List<Project>, NoParams> {
  GetProjectsUseCase(this._repo);
  final ProjectRepository _repo;

  @override
  Future<Either<Failure, List<Project>>> call(NoParams _) =>
      _repo.getProjects();
}

Either<Failure, Unit> _checkEndDate(DateTime createdAt, DateTime? endDate) {
  final start = DateTime(createdAt.year, createdAt.month, createdAt.day);
  if (endDate != null && endDate.isBefore(start)) {
    return const Left(
      ValidationFailure('Дата завершения раньше даты создания'),
    );
  }
  return const Right(unit);
}

/// Создатель проекта становится его Owner.
class CreateProjectUseCase
    implements UseCase<int, ({ProjectParams data, int? ownerId})> {
  CreateProjectUseCase(this._repo);
  final ProjectRepository _repo;

  @override
  Future<Either<Failure, int>> call(({ProjectParams data, int? ownerId}) p) =>
      eitherDo(($) async {
        final name = await $(
          Validators.text(p.data.name, 'Название', max: 100),
        );
        await $(_checkEndDate(DateTime.now(), p.data.endDate));
        return $(
          _repo.createProject(
            name: name,
            description: p.data.description.trim(),
            status: p.data.status,
            endDate: p.data.endDate,
            ownerId: p.ownerId,
          ),
        );
      });
}

class UpdateProjectUseCase
    implements UseCase<Unit, ({int id, ProjectParams data})> {
  UpdateProjectUseCase(this._repo);
  final ProjectRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(({int id, ProjectParams data}) p) =>
      eitherDo(($) async {
        final project = await $(_repo.getProject(p.id));
        if (project == null) fail(const NotFoundFailure('Проект не найден'));
        final name = await $(
          Validators.text(p.data.name, 'Название', max: 100),
        );
        await $(_checkEndDate(project.createdAt, p.data.endDate));
        return $(
          _repo.updateProject(
            p.id,
            name: name,
            description: p.data.description.trim(),
            status: p.data.status,
            endDate: p.data.endDate,
          ),
        );
      });
}

/// Задачи, участники и комментарии удаляются каскадно.
class DeleteProjectUseCase implements UseCase<Unit, int> {
  DeleteProjectUseCase(this._repo);
  final ProjectRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(int id) => _repo.deleteProject(id);
}

class WatchMembersUseCase implements StreamUseCase<List<ProjectMember>, int> {
  WatchMembersUseCase(this._repo);
  final ProjectRepository _repo;

  @override
  Stream<Either<Failure, List<ProjectMember>>> call(int projectId) =>
      _repo.watchMembers(projectId);
}

class GetProjectMembersUseCase implements UseCase<List<User>, int> {
  GetProjectMembersUseCase(this._repo);
  final ProjectRepository _repo;

  @override
  Future<Either<Failure, List<User>>> call(int projectId) =>
      _repo.getMembers(projectId);
}

class WatchUserProjectsUseCase implements StreamUseCase<List<Project>, int> {
  WatchUserProjectsUseCase(this._repo);
  final ProjectRepository _repo;

  @override
  Stream<Either<Failure, List<Project>>> call(int userId) =>
      _repo.watchProjectsOfUser(userId);
}

/// Одного пользователя нельзя добавить в проект дважды.
class AddMemberUseCase
    implements UseCase<Unit, ({int projectId, int userId, MemberRole role})> {
  AddMemberUseCase(this._repo);
  final ProjectRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(
    ({int projectId, int userId, MemberRole role}) p,
  ) => eitherDo(($) async {
    if (await $(_repo.isMember(p.projectId, p.userId))) {
      fail(const DuplicateMemberFailure());
    }
    return $(_repo.addMember(p.projectId, p.userId, p.role));
  });
}

class ChangeMemberRoleUseCase
    implements UseCase<Unit, ({int projectId, int userId, MemberRole role})> {
  ChangeMemberRoleUseCase(this._repo);
  final ProjectRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(
    ({int projectId, int userId, MemberRole role}) p,
  ) => _repo.changeRole(p.projectId, p.userId, p.role);
}

class RemoveMemberUseCase
    implements UseCase<Unit, ({int projectId, int userId})> {
  RemoveMemberUseCase(this._repo);
  final ProjectRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(({int projectId, int userId}) p) =>
      _repo.removeMember(p.projectId, p.userId);
}
