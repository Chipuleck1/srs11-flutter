import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../domain/entities/enums.dart';

/// Работа с таблицей users в SQLite. Возвращает строки Drift (UserRow).
class UserLocalDataSource {
  UserLocalDataSource(this._db);

  final AppDatabase _db;

  Stream<List<UserRow>> watchUsers({String search = '', int? limit}) {
    final q = _db.select(_db.users);
    final s = search.trim();
    if (s.isNotEmpty) {
      q.where(
        (u) => containsIgnoreCase(u.name, s) | containsIgnoreCase(u.email, s),
      );
    }
    q.orderBy([(u) => OrderingTerm.asc(u.name)]);
    if (limit != null) q.limit(limit);
    return q.watch();
  }

  Stream<UserRow?> watchUser(int id) => (_db.select(
    _db.users,
  )..where((u) => u.id.equals(id))).watchSingleOrNull();

  Future<UserRow?> getUser(int id) =>
      (_db.select(_db.users)..where((u) => u.id.equals(id))).getSingleOrNull();

  Future<bool> emailExists(String email, {int? exceptId}) async {
    final q = _db.select(_db.users)..where((u) => u.email.equals(email));
    if (exceptId != null) q.where((u) => u.id.equals(exceptId).not());
    return await q.getSingleOrNull() != null;
  }

  Future<int> insert({
    required String name,
    required String email,
    DateTime? registeredAt,
  }) => _db
      .into(_db.users)
      .insert(
        UsersCompanion.insert(
          name: name,
          email: email,
          registeredAt: registeredAt ?? DateTime.now(),
        ),
      );

  Future<void> update(int id, {required String name, required String email}) =>
      (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
        UsersCompanion(name: Value(name), email: Value(email)),
      );

  Future<int> countOpenTasks(int userId) async {
    final count = _db.tasks.id.count();
    final row =
        await (_db.selectOnly(_db.tasks)
              ..addColumns([count])
              ..where(
                _db.tasks.assigneeId.equals(userId) &
                    _db.tasks.deletedAt.isNull() &
                    _db.tasks.status.isIn([
                      TaskStatus.todo.name,
                      TaskStatus.inProgress.name,
                    ]),
              ))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// Членство и комментарии удаляются каскадно, у задач исполнитель → NULL.
  Future<void> delete(int id) =>
      (_db.delete(_db.users)..where((u) => u.id.equals(id))).go();
}
