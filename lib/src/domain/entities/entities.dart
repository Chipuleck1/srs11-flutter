// Сущности Domain Layer — чистый Dart, без Flutter, Drift и Dio.
import 'enums.dart';

export 'enums.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.registeredAt,
  });

  final int id;
  final String name;
  final String email;
  final DateTime registeredAt;
}

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.status,
    this.endDate,
  });

  final int id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime? endDate;
  final ProjectStatus status;
}

/// Проект с прогрессом — для списка проектов.
class ProjectSummary {
  const ProjectSummary({
    required this.project,
    required this.totalTasks,
    required this.doneTasks,
    required this.membersCount,
  });

  final Project project;
  final int totalTasks;
  final int doneTasks;
  final int membersCount;

  double get progress => totalTasks == 0 ? 0 : doneTasks / totalTasks;
}

class ProjectMember {
  const ProjectMember({required this.user, required this.role});

  final User user;
  final MemberRole role;
}

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

class Comment {
  const Comment({
    required this.id,
    required this.taskId,
    required this.author,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final int taskId;
  final User author;
  final String body;
  final DateTime createdAt;
}

class Attachment {
  const Attachment({
    required this.id,
    required this.taskId,
    required this.fileName,
    required this.filePath,
    required this.addedAt,
  });

  final int id;
  final int taskId;
  final String fileName;
  final String filePath;
  final DateTime addedAt;
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

class ProjectProgress {
  const ProjectProgress(this.projectId, this.name, this.total, this.done);

  final int projectId;
  final String name;
  final int total;
  final int done;

  double get percent => total == 0 ? 0 : done * 100 / total;
}

class AssigneeCount {
  const AssigneeCount(this.userId, this.name, this.count);

  final int? userId;
  final String name;
  final int count;
}

class DashboardStats {
  const DashboardStats({
    required this.projects,
    required this.tasks,
    required this.done,
    required this.open,
    required this.overdue,
    required this.byPriority,
    required this.byAssignee,
    required this.projectProgress,
  });

  final int projects;
  final int tasks;
  final int done;
  final int open;
  final int overdue;
  final Map<TaskPriority, int> byPriority;
  final List<AssigneeCount> byAssignee;
  final List<ProjectProgress> projectProgress;
}

class BenchmarkResult {
  const BenchmarkResult(this.name, this.withIndexMs, this.withoutIndexMs);

  final String name;
  final double withIndexMs;
  final double withoutIndexMs;

  double get speedup => withIndexMs == 0 ? 0 : withoutIndexMs / withIndexMs;
}

/// Результат новой функции «Импорт с сервера».
class ImportResult {
  const ImportResult({
    required this.projectId,
    required this.projectName,
    required this.usersCreated,
    required this.usersReused,
    required this.tasksCreated,
  });

  final int? projectId;
  final String projectName;
  final int usersCreated;
  final int usersReused;
  final int tasksCreated;

  bool get isEmpty =>
      tasksCreated == 0 && usersCreated == 0 && usersReused == 0;
}
