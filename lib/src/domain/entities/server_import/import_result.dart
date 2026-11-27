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
