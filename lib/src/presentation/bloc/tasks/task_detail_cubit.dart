import 'dart:async';

import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/models/enums.dart';
import 'package:lab11/src/domain/entities/tasks/task.dart';
import 'package:lab11/src/domain/usecases/tasks/task_usecases.dart';

// ---------------- задача ----------------

class TaskDetailCubit extends WatchCubit<TaskDetails?> {
  TaskDetailCubit(
    this.taskId,
    this._watch,
    this._status,
    this._undo,
    this._canUndo,
    this._priority,
    this._reassign,
    this._trash,
  ) {
    load();
  }

  final int taskId;
  final WatchTaskUseCase _watch;
  final ChangeTaskStatusUseCase _status;
  final UndoStatusChangeUseCase _undo;
  final CanUndoStatusChangeUseCase _canUndo;
  final ChangeTaskPriorityUseCase _priority;
  final ReassignTaskUseCase _reassign;
  final MoveTaskToTrashUseCase _trash;

  @override
  Stream<Either<Failure, TaskDetails?>> source() => _watch(taskId);

  @override
  bool isEmpty(TaskDetails? data) => data == null || data.task.isDeleted;

  Future<Failure?> changeStatus(TaskStatus s, int? actor) =>
      act(_status((id: taskId, status: s, actorId: actor)));
  Future<Failure?> undo(int? actor) =>
      act(_undo((taskId: taskId, actorId: actor)));
  Future<bool> canUndo() async =>
      (await _canUndo(taskId)).getOrElse((_) => false);
  Future<Failure?> changePriority(TaskPriority p) =>
      act(_priority((id: taskId, priority: p)));
  Future<Failure?> reassign(int? userId, int? actor) =>
      act(_reassign((id: taskId, assigneeId: userId, actorId: actor)));
  Future<Failure?> moveToTrash() => act(_trash(taskId));
}
