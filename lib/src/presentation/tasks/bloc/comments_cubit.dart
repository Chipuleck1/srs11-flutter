import 'dart:async';

import 'package:fpdart/fpdart.dart' hide Task;

import 'package:lab11/core/bloc/view_state.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/domain/tasks/entities/comment.dart';
import 'package:lab11/src/domain/tasks/usecases/comment_usecases.dart';

class CommentsCubit extends WatchCubit<List<Comment>> {
  CommentsCubit(this.taskId, this._watch, this._add, this._delete) {
    load();
  }
  final int taskId;
  final WatchCommentsUseCase _watch;
  final AddCommentUseCase _add;
  final DeleteCommentUseCase _delete;

  @override
  Stream<Either<Failure, List<Comment>>> source() => _watch(taskId);

  Future<Failure?> add(int? authorId, String text) =>
      act(_add((taskId: taskId, authorId: authorId, text: text)));
  Future<Failure?> delete(int commentId, int? actor) =>
      act(_delete((commentId: commentId, actorId: actor)));
}

class AttachmentsCubit extends WatchCubit<List<Attachment>> {
  AttachmentsCubit(this.taskId, this._watch, this._add, this._delete) {
    load();
  }
  final int taskId;
  final WatchAttachmentsUseCase _watch;
  final AddAttachmentUseCase _add;
  final DeleteAttachmentUseCase _delete;

  @override
  Stream<Either<Failure, List<Attachment>>> source() => _watch(taskId);

  Future<Failure?> add(String name, String path) =>
      act(_add((taskId: taskId, fileName: name, filePath: path)));
  Future<Failure?> delete(int id) => act(_delete(id));
}
