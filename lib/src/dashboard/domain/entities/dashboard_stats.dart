import 'package:lab11/models/enums.dart';

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
