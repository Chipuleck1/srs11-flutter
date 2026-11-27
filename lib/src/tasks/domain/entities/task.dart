import 'package:lab11/models/enums.dart';
import 'package:lab11/src/users/domain/entities/user.dart';

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.projectId,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.assigneeId,
    this.deadline,
    this.deletedAt,
  });

  final int id;
  final String title;
  final String description;
  final int projectId;
  final int? assigneeId;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  bool get isOverdue =>
      status.isOpen && deadline != null && deadline!.isBefore(DateTime.now());
}

/// Задача + название проекта + исполнитель — то, что показывает экран.
class TaskDetails {
  const TaskDetails({
    required this.task,
    required this.projectName,
    this.assignee,
  });

  final Task task;
  final String projectName;
  final User? assignee;
}

/// Данные новой задачи до сохранения.
class TaskDraft {
  const TaskDraft({
    required this.projectId,
    required this.title,
    this.description = '',
    this.assigneeId,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    this.deadline,
  });

  final int? projectId;
  final String title;
  final String description;
  final int? assigneeId;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? deadline;
}

enum TaskSort {
  createdDesc('Сначала новые'),
  createdAsc('Сначала старые'),
  deadlineAsc('Дедлайн: ближайшие'),
  deadlineDesc('Дедлайн: дальние');

  const TaskSort(this.label);
  final String label;
}

/// Параметры поиска, фильтрации, сортировки и пагинации задач.
class TaskFilter {
  const TaskFilter({
    this.search = '',
    this.status,
    this.priority,
    this.assigneeId,
    this.projectId,
    this.sort = TaskSort.createdDesc,
  });

  final String search;
  final TaskStatus? status;
  final TaskPriority? priority;
  final int? assigneeId;
  final int? projectId;
  final TaskSort sort;

  TaskFilter copyWith({
    String? search,
    TaskStatus? Function()? status,
    TaskPriority? Function()? priority,
    int? Function()? assigneeId,
    TaskSort? sort,
  }) => TaskFilter(
    search: search ?? this.search,
    status: status != null ? status() : this.status,
    priority: priority != null ? priority() : this.priority,
    assigneeId: assigneeId != null ? assigneeId() : this.assigneeId,
    projectId: projectId,
    sort: sort ?? this.sort,
  );
}

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.taskId,
    required this.event,
    required this.newStatus,
    required this.changedAt,
    required this.reverted,
    this.oldStatus,
    this.changedBy,
    this.details,
  });

  final int id;
  final int taskId;
  final HistoryEvent event;
  final TaskStatus? oldStatus;
  final TaskStatus newStatus;
  final User? changedBy;
  final DateTime changedAt;
  final String? details;
  final bool reverted;
}
