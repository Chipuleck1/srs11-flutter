import 'package:lab11/models/enums.dart';
import 'package:lab11/src/domain/entities/users/user.dart';

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
