import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../domain/entities/enums.dart';

typedef ProjectSummaryRow = ({
  ProjectRow project,
  int total,
  int done,
  int members,
});

class ProjectLocalDataSource {
  ProjectLocalDataSource(this._db);

  final AppDatabase _db;

  /// Проекты с прогрессом — один SQL-запрос с подзапросами.
  Stream<List<ProjectSummaryRow>> watchProjects() => _db
      .customSelect(
        '''
        SELECT p.*,
          (SELECT COUNT(*) FROM tasks t
            WHERE t.project_id = p.id AND t.deleted_at IS NULL) AS total,
          (SELECT COUNT(*) FROM tasks t
            WHERE t.project_id = p.id AND t.deleted_at IS NULL AND t.status = 'done') AS done,
          (SELECT COUNT(*) FROM project_members m WHERE m.project_id = p.id) AS members
        FROM projects p
        ORDER BY CASE p.status WHEN 'active' THEN 0 WHEN 'completed' THEN 1 ELSE 2 END,
                 p.created_at DESC
        ''',
        readsFrom: {_db.projects, _db.tasks, _db.projectMembers},
      )
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            (
              project: _db.projects.map(r.data),
              total: r.read<int>('total'),
              done: r.read<int>('done'),
              members: r.read<int>('members'),
            ),
        ],
      );

  Stream<ProjectRow?> watchProject(int id) => (_db.select(
    _db.projects,
  )..where((p) => p.id.equals(id))).watchSingleOrNull();

  Future<ProjectRow?> getProject(int id) => (_db.select(
    _db.projects,
  )..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<List<ProjectRow>> getProjects() => (_db.select(
    _db.projects,
  )..orderBy([(p) => OrderingTerm.asc(p.name)])).get();

  /// Проект + владелец — в одной транзакции.
  Future<int> insert({
    required String name,
    required String description,
    required ProjectStatus status,
    DateTime? endDate,
    int? ownerId,
  }) => _db.transaction(() async {
    final id = await _db
        .into(_db.projects)
        .insert(
          ProjectsCompanion.insert(
            name: name,
            description: Value(description),
            createdAt: DateTime.now(),
            endDate: Value(endDate),
            status: status,
          ),
        );
    if (ownerId != null) await addMember(id, ownerId, MemberRole.owner);
    return id;
  });

  Future<void> update(
    int id, {
    required String name,
    required String description,
    required ProjectStatus status,
    DateTime? endDate,
  }) => (_db.update(_db.projects)..where((p) => p.id.equals(id))).write(
    ProjectsCompanion(
      name: Value(name),
      description: Value(description),
      status: Value(status),
      endDate: Value(endDate),
    ),
  );

  Future<void> delete(int id) =>
      (_db.delete(_db.projects)..where((p) => p.id.equals(id))).go();

  Stream<List<({UserRow user, MemberRole role})>> watchMembers(int projectId) {
    final q =
        _db.select(_db.projectMembers).join([
            innerJoin(
              _db.users,
              _db.users.id.equalsExp(_db.projectMembers.userId),
            ),
          ])
          ..where(_db.projectMembers.projectId.equals(projectId))
          ..orderBy([OrderingTerm.asc(_db.users.name)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          (
            user: r.readTable(_db.users),
            role: r.readTable(_db.projectMembers).role,
          ),
      ],
    );
  }

  Future<List<UserRow>> getMembers(int projectId) {
    final q =
        _db.select(_db.users).join([
            innerJoin(
              _db.projectMembers,
              _db.projectMembers.userId.equalsExp(_db.users.id),
            ),
          ])
          ..where(_db.projectMembers.projectId.equals(projectId))
          ..orderBy([OrderingTerm.asc(_db.users.name)]);
    return q.map((r) => r.readTable(_db.users)).get();
  }

  Stream<List<ProjectRow>> watchProjectsOfUser(int userId) {
    final q = _db.select(_db.projects).join([
      innerJoin(
        _db.projectMembers,
        _db.projectMembers.projectId.equalsExp(_db.projects.id),
      ),
    ])..where(_db.projectMembers.userId.equals(userId));
    return q.map((r) => r.readTable(_db.projects)).watch();
  }

  Future<bool> isMember(int projectId, int userId) async =>
      await (_db.select(_db.projectMembers)..where(
            (m) => m.projectId.equals(projectId) & m.userId.equals(userId),
          ))
          .getSingleOrNull() !=
      null;

  Future<void> addMember(int projectId, int userId, MemberRole role) => _db
      .into(_db.projectMembers)
      .insert(
        ProjectMembersCompanion.insert(
          projectId: projectId,
          userId: userId,
          role: role,
          joinedAt: DateTime.now(),
        ),
      );

  Future<void> changeRole(int projectId, int userId, MemberRole role) =>
      (_db.update(_db.projectMembers)..where(
            (m) => m.projectId.equals(projectId) & m.userId.equals(userId),
          ))
          .write(ProjectMembersCompanion(role: Value(role)));

  /// Исключённый участник больше не исполнитель задач этого проекта.
  Future<void> removeMember(int projectId, int userId) =>
      _db.transaction(() async {
        await (_db.update(_db.tasks)..where(
              (t) =>
                  t.projectId.equals(projectId) & t.assigneeId.equals(userId),
            ))
            .write(
              TasksCompanion(
                assigneeId: const Value(null),
                updatedAt: Value(DateTime.now()),
              ),
            );
        await (_db.delete(_db.projectMembers)..where(
              (m) => m.projectId.equals(projectId) & m.userId.equals(userId),
            ))
            .go();
      });
}
