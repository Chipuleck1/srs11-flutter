import 'package:lab11/core/error/exceptions.dart';

/// Пользователь из GET /users (JSONPlaceholder).
class RemoteUserModel {
  const RemoteUserModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory RemoteUserModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final email = json['email'];
    if (id is! int || name is! String || email is! String) {
      throw ParseException('Некорректный пользователь: $json');
    }
    return RemoteUserModel(id: id, name: name, email: email);
  }

  final int id;
  final String name;
  final String email;
}

/// Задача из GET /todos (JSONPlaceholder).
class RemoteTodoModel {
  const RemoteTodoModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.completed,
  });

  factory RemoteTodoModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final userId = json['userId'];
    final title = json['title'];
    if (id is! int || userId is! int || title is! String) {
      throw ParseException('Некорректная задача: $json');
    }
    return RemoteTodoModel(
      id: id,
      userId: userId,
      title: title,
      completed: json['completed'] == true,
    );
  }

  final int id;
  final int userId;
  final String title;
  final bool completed;
}
