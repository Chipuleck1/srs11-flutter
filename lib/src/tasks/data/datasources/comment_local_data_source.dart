import 'package:drift/drift.dart';

import 'package:lab11/core/database/app_database.dart';

class CommentLocalDataSource {
  CommentLocalDataSource(this._db);

  final AppDatabase _db;

  Stream<List<({CommentRow comment, UserRow author})>> watchComments(
    int taskId,
  ) {
    final q =
        _db.select(_db.comments).join([
            innerJoin(_db.users, _db.users.id.equalsExp(_db.comments.authorId)),
          ])
          ..where(_db.comments.taskId.equals(taskId))
          ..orderBy([OrderingTerm.asc(_db.comments.createdAt)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          (comment: r.readTable(_db.comments), author: r.readTable(_db.users)),
      ],
    );
  }

  Future<CommentRow?> getComment(int id) => (_db.select(
    _db.comments,
  )..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> insertComment(int taskId, int authorId, String body) => _db
      .into(_db.comments)
      .insert(
        CommentsCompanion.insert(
          taskId: taskId,
          authorId: authorId,
          body: body,
          createdAt: DateTime.now(),
        ),
      );

  Future<void> deleteComment(int id) =>
      (_db.delete(_db.comments)..where((c) => c.id.equals(id))).go();

  Stream<List<AttachmentRow>> watchAttachments(int taskId) =>
      (_db.select(_db.attachments)
            ..where((a) => a.taskId.equals(taskId))
            ..orderBy([(a) => OrderingTerm.desc(a.addedAt)]))
          .watch();

  Future<int> insertAttachment(int taskId, String fileName, String filePath) =>
      _db
          .into(_db.attachments)
          .insert(
            AttachmentsCompanion.insert(
              taskId: taskId,
              fileName: fileName,
              filePath: filePath,
              addedAt: DateTime.now(),
            ),
          );

  Future<void> deleteAttachment(int id) =>
      (_db.delete(_db.attachments)..where((a) => a.id.equals(id))).go();
}
