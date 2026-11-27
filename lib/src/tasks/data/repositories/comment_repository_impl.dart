import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/error_handler.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/tasks/data/datasources/comment_local_data_source.dart';
import 'package:lab11/src/tasks/data/mapper/task_mapper.dart';
import 'package:lab11/src/tasks/domain/entities/comment.dart';
import 'package:lab11/src/tasks/domain/repositories/comment_repository.dart';

class CommentRepositoryImpl implements CommentRepository {
  CommentRepositoryImpl(this._local);
  final CommentLocalDataSource _local;

  @override
  Stream<Either<Failure, List<Comment>>> watchComments(int taskId) =>
      ErrorHandler.guardStream(
        _local
            .watchComments(taskId)
            .map(
              (rows) => [for (final r in rows) toComment(r.comment, r.author)],
            ),
      );

  @override
  Future<Either<Failure, int?>> getCommentAuthorId(int commentId) =>
      ErrorHandler.guard(
        () async => (await _local.getComment(commentId))?.authorId,
      );

  @override
  Future<Either<Failure, int>> addComment(
    int taskId,
    int authorId,
    String body,
  ) => ErrorHandler.guard(() => _local.insertComment(taskId, authorId, body));

  @override
  Future<Either<Failure, Unit>> deleteComment(int commentId) =>
      ErrorHandler.guard(() async {
        await _local.deleteComment(commentId);
        return unit;
      });

  @override
  Stream<Either<Failure, List<Attachment>>> watchAttachments(int taskId) =>
      ErrorHandler.guardStream(
        _local
            .watchAttachments(taskId)
            .map((rows) => rows.map((r) => r.toEntity()).toList()),
      );

  @override
  Future<Either<Failure, int>> addAttachment(
    int taskId, {
    required String fileName,
    required String filePath,
  }) => ErrorHandler.guard(
    () => _local.insertAttachment(taskId, fileName, filePath),
  );

  @override
  Future<Either<Failure, Unit>> deleteAttachment(int id) =>
      ErrorHandler.guard(() async {
        await _local.deleteAttachment(id);
        return unit;
      });
}
