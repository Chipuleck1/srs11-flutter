import 'package:lab11/core/database/app_database.dart';
import 'package:lab11/src/domain/users/entities/user.dart';

extension UserRowMapper on UserRow {
  User toEntity() =>
      User(id: id, name: name, email: email, registeredAt: registeredAt);
}
