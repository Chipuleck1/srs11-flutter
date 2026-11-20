import 'package:fpdart/fpdart.dart' hide Task;

import '../../../core/error/failures.dart';
import '../../../core/usecase/usecase.dart';
import '../entities/entities.dart';
import '../repositories/project_repository.dart';
import '../repositories/task_repository.dart';
import 'validators.dart';

/// Бизнес-правило: не больше 3 незавершённых задач у исполнителя на один дедлайн.
const maxOpenTasksPerDeadline = 3;

Future<Either<Failure, Unit>> _checkCapacity(
  TaskRepository repo,
  int assigneeId,
  DateTime? deadline, {
  int? excludeTaskId,
}) => eitherDo(($) async {
  if (deadline == null) return unit;
  final count = await $(
    repo.countOpenTasksOnDay(
      assigneeId,
      deadline,
      excludeTaskId: excludeTaskId,
    ),
  );
  if (count >= maxOpenTasksPerDeadline) fail(const AssigneeOverloadedFailure());
  return unit;
});

Future<Either<Failure, Unit>> _checkMember(
  ProjectRepository projects,
  int projectId,
  int userId,
) => eitherDo(($) async {
  if (!await $(projects.isMember(projectId, userId))) {
    fail(const NotProjectMemberFailure());
  }
  return unit;
});

Future<Either<Failure, Task>> _requireTask(TaskRepository repo, int id) =>
    eitherDo(($) async {
      final task = await $(repo.getTask(id));
      if (task == null || task.isDeleted) {
        fail(const NotFoundFailure('Задача не найдена'));
      }
      return task;
    });

// ---------------- чтение ----------------

class WatchTasksUseCase
    implements
        StreamUseCase<List<TaskDetails>, ({TaskFilter filter, int limit})> {
  WatchTasksUseCase(this._repo);
  final TaskRepository _repo;

  @override
  Stream<Either<Failure, List<TaskDetails>>> call(
    ({TaskFilter filter, int limit}) p,
  ) => _repo.watchTasks(p.filter, limit: p.limit);
}

class WatchTaskCountUseCase implements StreamUseCase<int, TaskFilter> {
  WatchTaskCountUseCase(this._repo);
  final TaskRepository _repo;

  @override
  Stream<Either<Failure, int>> call(TaskFilter filter) =>
      _repo.watchCount(filter);
}

class WatchTaskUseCase implements StreamUseCase<TaskDetails?, int> {
  WatchTaskUseCase(this._repo);
  final TaskRepository _repo;

  @override
  Stream<Either<Failure, TaskDetails?>> call(int id) => _repo.watchTask(id);
}

class WatchTaskHistoryUseCase
    implements StreamUseCase<List<HistoryEntry>, int> {
  WatchTaskHistoryUseCase(this._repo);
  final TaskRepository _repo;

  @override
  Stream<Either<Failure, List<HistoryEntry>>> call(int taskId) =>
      _repo.watchHistory(taskId);
}

class WatchTrashUseCase implements StreamUseCase<List<TaskDetails>, NoParams> {
  WatchTrashUseCase(this._repo);
  final TaskRepository _repo;

  @override
  Stream<Either<Failure, List<TaskDetails>>> call(NoParams _) =>
      _repo.watchTrash();
}

// ---------------- создание и изменение ----------------

/// Создание задачи: проект обязателен, исполнитель — участник проекта,
/// лимит задач на дедлайн. Задача и первая запись истории сохраняются атомарно.
class CreateTaskUseCase
    implements UseCase<int, ({TaskDraft draft, int? actorId})> {
  CreateTaskUseCase(this._tasks, this._projects);
  final TaskRepository _tasks;
  final ProjectRepository _projects;

  @override
  Future<Either<Failure, int>> call(({TaskDraft draft, int? actorId}) p) =>
      eitherDo(($) async {
        final d = p.draft;
        final title = await $(Validators.text(d.title, 'Название', max: 200));
        final projectId = d.projectId;
        if (projectId == null) {
          fail(const ValidationFailure('Задача должна принадлежать проекту'));
        }
        if (await $(_projects.getProject(projectId)) == null) {
          fail(const NotFoundFailure('Проект не найден'));
        }
        if (d.assigneeId != null) {
          await $(_checkMember(_projects, projectId, d.assigneeId!));
          if (d.status.isOpen) {
            await $(_checkCapacity(_tasks, d.assigneeId!, d.deadline));
          }
        }
        final clean = TaskDraft(
          projectId: projectId,
          title: title,
          description: d.description.trim(),
          assigneeId: d.assigneeId,
          priority: d.priority,
          status: d.status,
          deadline: d.deadline,
        );
        return $(_tasks.createTask(clean, actorId: p.actorId));
      });
}

typedef UpdateTaskParams = ({
  int id,
  String title,
  String description,
  TaskPriority priority,
  DateTime? deadline,
});

class UpdateTaskUseCase implements UseCase<Unit, UpdateTaskParams> {
  UpdateTaskUseCase(this._repo);
  final TaskRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(UpdateTaskParams p) => eitherDo(($) async {
    final task = await $(_requireTask(_repo, p.id));
    final title = await $(Validators.text(p.title, 'Название', max: 200));
    if (task.assigneeId != null &&
        task.status.isOpen &&
        !_sameDay(task.deadline, p.deadline)) {
      await $(
        _checkCapacity(
          _repo,
          task.assigneeId!,
          p.deadline,
          excludeTaskId: p.id,
        ),
      );
    }
    return $(
      _repo.updateTask(
        p.id,
        title: title,
        description: p.description.trim(),
        priority: p.priority,
        deadline: p.deadline,
      ),
    );
  });

  bool _sameDay(DateTime? a, DateTime? b) =>
      a?.year == b?.year && a?.month == b?.month && a?.day == b?.day;
}

class ChangeTaskPriorityUseCase
    implements UseCase<Unit, ({int id, TaskPriority priority})> {
  ChangeTaskPriorityUseCase(this._repo);
  final TaskRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(({int id, TaskPriority priority}) p) =>
      eitherDo(($) async {
        await $(_requireTask(_repo, p.id));
        return $(_repo.changePriority(p.id, p.priority));
      });
}

/// Смена статуса; запись в историю создаётся автоматически.
class ChangeTaskStatusUseCase
    implements UseCase<Unit, ({int id, TaskStatus status, int? actorId})> {
  ChangeTaskStatusUseCase(this._repo);
  final TaskRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(
    ({int id, TaskStatus status, int? actorId}) p,
  ) => eitherDo(($) async {
    final task = await $(_requireTask(_repo, p.id));
    if (task.status == p.status) return unit;
    // Возврат в работу снова занимает «слот» исполнителя на дедлайн
    if (!task.status.isOpen && p.status.isOpen && task.assigneeId != null) {
      await $(
        _checkCapacity(
          _repo,
          task.assigneeId!,
          task.deadline,
          excludeTaskId: p.id,
        ),
      );
    }
    return $(_repo.changeStatus(p.id, p.status, actorId: p.actorId));
  });
}

/// Переназначение: проверка участия в проекте и лимита, затем атомарная запись.
class ReassignTaskUseCase
    implements UseCase<Unit, ({int id, int? assigneeId, int? actorId})> {
  ReassignTaskUseCase(this._tasks, this._projects);
  final TaskRepository _tasks;
  final ProjectRepository _projects;

  @override
  Future<Either<Failure, Unit>> call(
    ({int id, int? assigneeId, int? actorId}) p,
  ) => eitherDo(($) async {
    final task = await $(_requireTask(_tasks, p.id));
    if (task.assigneeId == p.assigneeId) return unit;
    final newId = p.assigneeId;
    if (newId != null) {
      await $(_checkMember(_projects, task.projectId, newId));
      if (task.status.isOpen) {
        await $(
          _checkCapacity(_tasks, newId, task.deadline, excludeTaskId: p.id),
        );
      }
    }
    return $(_tasks.reassign(p.id, newId, actorId: p.actorId));
  });
}

/// Undo: вернуть статус, который был до последнего изменения.
class UndoStatusChangeUseCase
    implements UseCase<Unit, ({int taskId, int? actorId})> {
  UndoStatusChangeUseCase(this._repo);
  final TaskRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(({int taskId, int? actorId}) p) =>
      eitherDo(($) async {
        await $(_requireTask(_repo, p.taskId));
        final last = await $(_repo.lastRevertibleStatusChange(p.taskId));
        if (last == null || last.oldStatus == null) {
          fail(const NothingToUndoFailure());
        }
        return $(_repo.revertStatusChange(last, actorId: p.actorId));
      });
}

class CanUndoStatusChangeUseCase implements UseCase<bool, int> {
  CanUndoStatusChangeUseCase(this._repo);
  final TaskRepository _repo;

  @override
  Future<Either<Failure, bool>> call(int taskId) => _repo
      .lastRevertibleStatusChange(taskId)
      .then((e) => e.map((h) => h?.oldStatus != null));
}

// ---------------- корзина (soft delete) ----------------

class MoveTaskToTrashUseCase implements UseCase<Unit, int> {
  MoveTaskToTrashUseCase(this._repo);
  final TaskRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(int id) => eitherDo(($) async {
    await $(_requireTask(_repo, id));
    return $(_repo.softDelete(id));
  });
}

class RestoreTaskUseCase implements UseCase<Unit, int> {
  RestoreTaskUseCase(this._repo);
  final TaskRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(int id) => eitherDo(($) async {
    if (await $(_repo.getTask(id)) == null) {
      fail(const NotFoundFailure('Задача не найдена'));
    }
    return $(_repo.restore(id));
  });
}

class DeleteTaskForeverUseCase implements UseCase<Unit, int> {
  DeleteTaskForeverUseCase(this._repo);
  final TaskRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(int id) => _repo.deleteForever(id);
}

class EmptyTrashUseCase implements UseCase<Unit, NoParams> {
  EmptyTrashUseCase(this._repo);
  final TaskRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams _) => _repo.emptyTrash();
}
