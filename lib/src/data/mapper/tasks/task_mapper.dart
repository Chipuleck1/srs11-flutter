import 'package:lab11/src/domain/entities/users/user.dart';
import 'package:lab11/core/database/app_database.dart';
import 'package:lab11/src/domain/entities/tasks/comment.dart';
import 'package:lab11/src/domain/entities/tasks/task.dart';

extension TaskRowMapper on TaskRow {
  Task toEntity() => Task(
    id: id,
    title: title,
    description: description,
    projectId: projectId,
    assigneeId: assigneeId,
    priority: priority,
    status: status,
    deadline: deadline,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

extension AttachmentRowMapper on AttachmentRow {
  Attachment toEntity() => Attachment(
    id: id,
    taskId: taskId,
    fileName: fileName,
    filePath: filePath,
    addedAt: addedAt,
  );
}

extension HistoryRowMapper on HistoryRow {
  HistoryEntry toEntity({UserRow? user}) => HistoryEntry(
    id: id,
    taskId: taskId,
    event: event,
    oldStatus: oldStatus,
    newStatus: newStatus,
    changedBy: user == null ? null : _user(user),
    changedAt: changedAt,
    details: details,
    reverted: reverted,
  );
}

TaskDetails toTaskDetails(
  TaskRow task,
  ProjectRow project,
  UserRow? assignee,
) => TaskDetails(
  task: task.toEntity(),
  projectName: project.name,
  assignee: assignee == null ? null : _user(assignee),
);

Comment toComment(CommentRow c, UserRow author) => Comment(
  id: c.id,
  taskId: c.taskId,
  author: _user(author),
  body: c.body,
  createdAt: c.createdAt,
);

/// Пользователь из строки БД (своя копия маппера, чтобы фича не зависела от data другой фичи).
User _user(UserRow r) =>
    User(id: r.id, name: r.name, email: r.email, registeredAt: r.registeredAt);
