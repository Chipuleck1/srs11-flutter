import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/tasks/domain/entities/comment.dart';

/// Комментарии и вложения задачи.
abstract interface class CommentRepository {
  Stream<Either<Failure, List<Comment>>> watchComments(int taskId);
  Future<Either<Failure, int?>> getCommentAuthorId(int commentId);
  Future<Either<Failure, int>> addComment(
    int taskId,
    int authorId,
    String body,
  );
  Future<Either<Failure, Unit>> deleteComment(int commentId);

  Stream<Either<Failure, List<Attachment>>> watchAttachments(int taskId);
  Future<Either<Failure, int>> addAttachment(
    int taskId, {
    required String fileName,
    required String filePath,
  });
  Future<Either<Failure, Unit>> deleteAttachment(int id);
}
