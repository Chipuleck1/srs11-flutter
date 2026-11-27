import 'package:lab11/src/domain/tasks/entities/task.dart';

/// Задача в корзине (soft delete): сама задача + когда её удалили.
class TrashItem {
  const TrashItem({required this.details, required this.deletedAt});

  final TaskDetails details;
  final DateTime deletedAt;

  int get taskId => details.task.id;
}
