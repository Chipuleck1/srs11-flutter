// Преобразование моделей Data Layer (строки Drift) в сущности Domain.
import '../../../core/database/app_database.dart';
import '../../domain/entities/entities.dart';

extension UserRowMapper on UserRow {
  User toEntity() =>
      User(id: id, name: name, email: email, registeredAt: registeredAt);
}

extension ProjectRowMapper on ProjectRow {
  Project toEntity() => Project(
    id: id,
    name: name,
    description: description,
    createdAt: createdAt,
    endDate: endDate,
    status: status,
  );
}

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
    changedBy: user?.toEntity(),
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
  assignee: assignee?.toEntity(),
);

Comment toComment(CommentRow c, UserRow author) => Comment(
  id: c.id,
  taskId: c.taskId,
  author: author.toEntity(),
  body: c.body,
  createdAt: c.createdAt,
);
