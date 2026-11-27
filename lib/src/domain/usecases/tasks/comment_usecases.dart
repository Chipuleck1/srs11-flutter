import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/core/usecase/usecase.dart';
import 'package:lab11/core/validation/validators.dart';
import 'package:lab11/src/domain/entities/tasks/comment.dart';
import 'package:lab11/src/domain/repositories/tasks/comment_repository.dart';
import 'package:lab11/src/domain/repositories/tasks/task_repository.dart';

class WatchCommentsUseCase implements StreamUseCase<List<Comment>, int> {
  WatchCommentsUseCase(this._repo);
  final CommentRepository _repo;

  @override
  Stream<Either<Failure, List<Comment>>> call(int taskId) =>
      _repo.watchComments(taskId);
}

/// Комментарий можно добавить только к существующей задаче.
class AddCommentUseCase
    implements UseCase<int, ({int taskId, int? authorId, String text})> {
  AddCommentUseCase(this._comments, this._tasks);
  final CommentRepository _comments;
  final TaskRepository _tasks;

  @override
  Future<Either<Failure, int>> call(
    ({int taskId, int? authorId, String text}) p,
  ) => eitherDo(($) async {
    final authorId = p.authorId;
    if (authorId == null) {
      fail(const ValidationFailure('Выберите текущего пользователя'));
    }
    final body = await $(Validators.text(p.text, 'Комментарий', max: 2000));
    final task = await $(_tasks.getTask(p.taskId));
    if (task == null || task.isDeleted) {
      fail(
        const NotFoundFailure('Нельзя комментировать несуществующую задачу'),
      );
    }
    return $(_comments.addComment(p.taskId, authorId, body));
  });
}

/// Удалять комментарий может только его автор.
class DeleteCommentUseCase
    implements UseCase<Unit, ({int commentId, int? actorId})> {
  DeleteCommentUseCase(this._repo);
  final CommentRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(
    ({int commentId, int? actorId}) p,
  ) => eitherDo(($) async {
    final authorId = await $(_repo.getCommentAuthorId(p.commentId));
    if (authorId == null) fail(const NotFoundFailure('Комментарий не найден'));
    if (authorId != p.actorId) {
      fail(
        const ForbiddenFailure('Удалить комментарий может только его автор'),
      );
    }
    return $(_repo.deleteComment(p.commentId));
  });
}

class WatchAttachmentsUseCase implements StreamUseCase<List<Attachment>, int> {
  WatchAttachmentsUseCase(this._repo);
  final CommentRepository _repo;

  @override
  Stream<Either<Failure, List<Attachment>>> call(int taskId) =>
      _repo.watchAttachments(taskId);
}

/// В базе хранится путь к файлу, а не его содержимое.
class AddAttachmentUseCase
    implements UseCase<int, ({int taskId, String fileName, String filePath})> {
  AddAttachmentUseCase(this._comments, this._tasks);
  final CommentRepository _comments;
  final TaskRepository _tasks;

  @override
  Future<Either<Failure, int>> call(
    ({int taskId, String fileName, String filePath}) p,
  ) => eitherDo(($) async {
    final name = await $(Validators.text(p.fileName, 'Имя файла', max: 255));
    final path = await $(Validators.text(p.filePath, 'Путь', max: 4096));
    if (await $(_tasks.getTask(p.taskId)) == null) {
      fail(const NotFoundFailure('Задача не найдена'));
    }
    return $(_comments.addAttachment(p.taskId, fileName: name, filePath: path));
  });
}

class DeleteAttachmentUseCase implements UseCase<Unit, int> {
  DeleteAttachmentUseCase(this._repo);
  final CommentRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(int id) => _repo.deleteAttachment(id);
}
