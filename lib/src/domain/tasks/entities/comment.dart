import 'package:lab11/src/domain/users/entities/user.dart';

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
