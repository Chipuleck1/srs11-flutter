import 'package:flutter_test/flutter_test.dart';

import 'package:lab11/core/di/injection.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/core/usecase/usecase.dart';
import 'package:lab11/models/enums.dart';
import 'package:lab11/src/dashboard/domain/usecases/watch_dashboard_usecase.dart';
import 'package:lab11/src/projects/domain/usecases/project_usecases.dart';
import 'package:lab11/src/tasks/domain/entities/task.dart';
import 'package:lab11/src/tasks/domain/usecases/comment_usecases.dart';
import 'package:lab11/src/tasks/domain/usecases/task_usecases.dart';
import 'package:lab11/src/trash/domain/usecases/trash_usecases.dart';
import 'package:lab11/src/users/domain/usecases/user_usecases.dart';

import 'helpers.dart';

/// Бизнес-правила проверяются через UseCase-ы (Domain) на настоящей SQLite в памяти.
void main() {
  setUp(setUpApp);
  tearDown(tearDownApp);

  group('Пользователи', () {
    test('1. создание пользователя, email нормализуется', () async {
      final id = right(
        await getIt<CreateUserUseCase>()((
          name: ' Анна ',
          email: 'Anna@Mail.KZ',
        )),
      );
      final u = right(await getIt<GetUserUseCase>()(id))!;
      expect(u.name, 'Анна');
      expect(u.email, 'anna@mail.kz');
    });

    test('2. уникальность email → DuplicateEmailFailure', () async {
      await getIt<CreateUserUseCase>()((name: 'Анна', email: 'a@test.kz'));
      final f = left(
        await getIt<CreateUserUseCase>()((name: 'Другая', email: 'A@test.kz')),
      );
      expect(f, isA<DuplicateEmailFailure>());
    });

    test(
      '3. некорректные данные → ValidationFailure, ничего не сохраняется',
      () async {
        expect(
          left(await getIt<CreateUserUseCase>()((name: '', email: 'a@b.kz'))),
          isA<ValidationFailure>(),
        );
        expect(
          left(await getIt<CreateUserUseCase>()((name: 'A', email: 'нет'))),
          isA<ValidationFailure>(),
        );
        expect(await count('users'), 0);
      },
    );

    test('4. нельзя удалить пользователя с незавершёнными задачами', () async {
      final anna = await newUser();
      final p = await newProject([anna]);
      final t = right(await createTask(p, assigneeId: anna));

      expect(
        left(await getIt<DeleteUserUseCase>()(anna)),
        isA<UserHasOpenTasksFailure>(),
      );

      right(
        await getIt<ChangeTaskStatusUseCase>()((
          id: t,
          status: TaskStatus.done,
          actorId: anna,
        )),
      );
      right(await getIt<DeleteUserUseCase>()(anna));
      expect((await task(t)).assigneeId, isNull); // ON DELETE SET NULL
    });
  });

  group('Проекты', () {
    test('5. создание проекта, создатель становится Owner', () async {
      final anna = await newUser();
      final id = right(
        await getIt<CreateProjectUseCase>()((
          data: (
            name: 'Сайт',
            description: '',
            status: ProjectStatus.active,
            endDate: null,
          ),
          ownerId: anna,
        )),
      );
      final members = right(await getIt<WatchMembersUseCase>()(id).first);
      expect(members.single.role, MemberRole.owner);
    });

    test(
      '6. повторное добавление участника → DuplicateMemberFailure',
      () async {
        final anna = await newUser();
        final p = await newProject([anna]);
        final f = left(
          await getIt<AddMemberUseCase>()((
            projectId: p,
            userId: anna,
            role: MemberRole.admin,
          )),
        );
        expect(f, isA<DuplicateMemberFailure>());
      },
    );

    test('7. удаление проекта удаляет задачи и комментарии каскадно', () async {
      final anna = await newUser();
      final p = await newProject([anna]);
      final t = right(await createTask(p, actorId: anna));
      right(
        await getIt<AddCommentUseCase>()((
          taskId: t,
          authorId: anna,
          text: 'Привет',
        )),
      );

      right(await getIt<DeleteProjectUseCase>()(p));
      expect(await count('tasks'), 0);
      expect(await count('comments'), 0);
      expect(await count('task_history'), 0);
    });
  });

  group('Задачи', () {
    late int anna, ivan, project;

    setUp(() async {
      anna = await newUser('Анна');
      ivan = await newUser('Иван');
      project = await newProject([anna]); // Иван не участник
    });

    test('8. создание задачи + первая запись истории', () async {
      final id = right(
        await createTask(
          project,
          title: 'Сверстать',
          assigneeId: anna,
          actorId: anna,
        ),
      );
      final history = right(await getIt<WatchTaskHistoryUseCase>()(id).first);
      expect(history.single.event, HistoryEvent.created);
      expect(history.single.changedBy?.id, anna);
    });

    test(
      '9. задача без проекта / в несуществующем проекте запрещена',
      () async {
        expect(left(await createTask(null)), isA<ValidationFailure>());
        expect(left(await createTask(9999)), isA<NotFoundFailure>());
        expect(await count('tasks'), 0);
      },
    );

    test('10. исполнитель должен быть участником проекта', () async {
      expect(
        left(await createTask(project, assigneeId: ivan)),
        isA<NotProjectMemberFailure>(),
      );
      final id = right(await createTask(project, assigneeId: anna));
      expect(
        left(
          await getIt<ReassignTaskUseCase>()((
            id: id,
            assigneeId: ivan,
            actorId: anna,
          )),
        ),
        isA<NotProjectMemberFailure>(),
      );
    });

    test('11. смена статуса пишет историю (старый → новый, кто)', () async {
      final id = right(await createTask(project, actorId: anna));
      right(
        await getIt<ChangeTaskStatusUseCase>()((
          id: id,
          status: TaskStatus.inProgress,
          actorId: anna,
        )),
      );
      final h = right(await getIt<WatchTaskHistoryUseCase>()(id).first).reversed
          .toList();
      expect(h[1].oldStatus, TaskStatus.todo);
      expect(h[1].newStatus, TaskStatus.inProgress);
      expect(h[1].changedBy?.id, anna);
    });

    test('12. транзакция: ошибка истории откатывает создание задачи', () async {
      // actorId = 9999 нарушает внешний ключ истории → задача тоже не сохраняется
      expect(left(await createTask(project, actorId: 9999)), isA<Failure>());
      expect(await count('tasks'), 0);
      expect(await count('task_history'), 0);
    });

    test('13. Undo возвращает предыдущий статус', () async {
      final id = right(await createTask(project, actorId: anna));
      expect(
        left(
          await getIt<UndoStatusChangeUseCase>()((taskId: id, actorId: anna)),
        ),
        isA<NothingToUndoFailure>(),
      );
      right(
        await getIt<ChangeTaskStatusUseCase>()((
          id: id,
          status: TaskStatus.done,
          actorId: anna,
        )),
      );
      right(
        await getIt<UndoStatusChangeUseCase>()((taskId: id, actorId: anna)),
      );
      expect((await task(id)).status, TaskStatus.todo);
      expect(right(await getIt<CanUndoStatusChangeUseCase>()(id)), isFalse);
    });

    test('14. не больше 3 незавершённых задач на один дедлайн', () async {
      final day = DateTime(2030, 5, 20, 10);
      for (var i = 0; i < 3; i++) {
        right(
          await createTask(
            project,
            assigneeId: anna,
            deadline: day.add(Duration(hours: i)),
          ),
        );
      }
      expect(
        left(await createTask(project, assigneeId: anna, deadline: day)),
        isA<AssigneeOverloadedFailure>(),
      );
      right(
        await createTask(
          project,
          assigneeId: anna,
          deadline: DateTime(2030, 5, 21),
        ),
      );
    });

    test('15. soft delete и восстановление', () async {
      final id = right(await createTask(project));
      right(await getIt<MoveTaskToTrashUseCase>()(id));
      expect(
        right(await getIt<WatchTrashUseCase>()(const NoParams()).first)
            .single
            .task
            .id,
        id,
      );
      expect(
        right(
          await getIt<WatchTasksUseCase>()((
            filter: TaskFilter(projectId: project),
            limit: 30,
          )).first,
        ),
        isEmpty,
      );
      right(await getIt<RestoreTaskUseCase>()(id));
      expect((await task(id)).deletedAt, isNull);
    });

    test(
      '16. комментарии: только к существующей задаче, удаляет только автор',
      () async {
        final id = right(await createTask(project));
        expect(
          left(
            await getIt<AddCommentUseCase>()((
              taskId: 999,
              authorId: anna,
              text: 'x',
            )),
          ),
          isA<NotFoundFailure>(),
        );
        final c = right(
          await getIt<AddCommentUseCase>()((
            taskId: id,
            authorId: anna,
            text: 'Первый',
          )),
        );
        expect(
          left(
            await getIt<DeleteCommentUseCase>()((commentId: c, actorId: ivan)),
          ),
          isA<ForbiddenFailure>(),
        );
        right(
          await getIt<DeleteCommentUseCase>()((commentId: c, actorId: anna)),
        );
        expect(await count('comments'), 0);
      },
    );

    test(
      '17. поиск без учёта регистра, фильтр, сортировка, пагинация',
      () async {
        final base = DateTime(2030, 1, 1);
        right(
          await createTask(
            project,
            title: 'Дизайн логотипа',
            deadline: base.add(const Duration(days: 3)),
          ),
        );
        right(
          await createTask(
            project,
            title: 'API',
            description: 'нужен дизайн',
            deadline: base,
          ),
        );
        right(
          await createTask(
            project,
            title: 'Тесты',
            priority: TaskPriority.high,
            deadline: base.add(const Duration(days: 1)),
          ),
        );

        Future<List<String>> titles(TaskFilter f, [int limit = 30]) async =>
            right(
              await getIt<WatchTasksUseCase>()((filter: f, limit: limit)).first,
            ).map((t) => t.task.title).toList();

        expect((await titles(const TaskFilter(search: 'ДИЗАЙН'))).toSet(), {
          'Дизайн логотипа',
          'API',
        });
        expect(await titles(const TaskFilter(priority: TaskPriority.high)), [
          'Тесты',
        ]);
        expect(await titles(const TaskFilter(sort: TaskSort.deadlineAsc)), [
          'API',
          'Тесты',
          'Дизайн логотипа',
        ]);
        expect(await titles(const TaskFilter(sort: TaskSort.deadlineAsc), 2), [
          'API',
          'Тесты',
        ]);
      },
    );

    test('18. статистика считается SQL-запросами', () async {
      right(
        await createTask(
          project,
          assigneeId: anna,
          priority: TaskPriority.critical,
          deadline: DateTime.now().subtract(const Duration(days: 2)),
        ),
      );
      final done = right(await createTask(project));
      right(
        await getIt<ChangeTaskStatusUseCase>()((
          id: done,
          status: TaskStatus.done,
          actorId: anna,
        )),
      );

      final s = right(
        await getIt<WatchDashboardUseCase>()(const NoParams()).first,
      );
      expect(s.tasks, 2);
      expect(s.done, 1);
      expect(s.overdue, 1);
      expect(s.byPriority[TaskPriority.critical], 1);
      expect(s.projectProgress.single.percent, 50);
    });
  });
}
