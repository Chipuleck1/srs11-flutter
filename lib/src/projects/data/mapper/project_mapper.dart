import 'package:lab11/core/database/app_database.dart';
import 'package:lab11/src/projects/domain/entities/project.dart';

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
