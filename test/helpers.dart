import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lab11/core/database/app_database.dart';
import 'package:lab11/core/di/injection.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/models/enums.dart';
import 'package:lab11/src/domain/usecases/projects/project_usecases.dart';
import 'package:lab11/src/domain/entities/tasks/task.dart';
import 'package:lab11/src/domain/repositories/tasks/task_repository.dart';
import 'package:lab11/src/domain/usecases/tasks/task_usecases.dart';
import 'package:lab11/src/domain/usecases/users/user_usecases.dart';

/// Ответ поддельного сервера: JSON или сетевая ошибка.
class FakeServer implements HttpClientAdapter {
  Object? Function(RequestOptions o) handler = (_) => [];
  int status = 200;
  bool offline = false;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    requests.add(o);
    if (offline) {
      throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(handler(o)),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Полный DI приложения, но база SQLite — в памяти, сервер — поддельный.
Future<FakeServer> setUpApp() async {
  await getIt.reset();
  SharedPreferences.setMockInitialValues({});
  final server = FakeServer();
  await configureDependencies(
    executor: NativeDatabase.memory(setup: registerSqlFunctions),
    prefs: await SharedPreferences.getInstance(),
    httpAdapter: server,
  );
  return server;
}

Future<void> tearDownApp() => getIt.reset();

/// Значение Right или падение теста.
T right<T>(Either<Failure, T> e) =>
    e.getOrElse((f) => throw StateError('Ожидался успех, а пришло: $f'));

/// Failure из Left или падение теста.
Failure left<T>(Either<Failure, T> e) =>
    e.getLeft().getOrElse(() => throw StateError('Ожидалась ошибка'));

int _n = 0;

Future<int> newUser([String name = 'Анна']) async => right(
  await getIt<CreateUserUseCase>()((name: name, email: 'user${_n++}@test.kz')),
);

Future<int> newProject(List<int> members, {String name = 'Проект'}) async {
  final id = right(
    await getIt<CreateProjectUseCase>()((
      data: (
        name: name,
        description: '',
        status: ProjectStatus.active,
        endDate: null,
      ),
      ownerId: null,
    )),
  );
  for (final m in members) {
    right(
      await getIt<AddMemberUseCase>()((
        projectId: id,
        userId: m,
        role: MemberRole.member,
      )),
    );
  }
  return id;
}

Future<Either<Failure, int>> createTask(
  int? projectId, {
  String title = 'Задача',
  String description = '',
  int? assigneeId,
  int? actorId,
  TaskPriority priority = TaskPriority.medium,
  TaskStatus status = TaskStatus.todo,
  DateTime? deadline,
}) => getIt<CreateTaskUseCase>()((
  draft: TaskDraft(
    projectId: projectId,
    title: title,
    description: description,
    assigneeId: assigneeId,
    priority: priority,
    status: status,
    deadline: deadline,
  ),
  actorId: actorId,
));

Future<int> count(String table) async =>
    (await getIt<AppDatabase>()
            .customSelect('SELECT COUNT(*) AS c FROM $table')
            .getSingle())
        .read<int>('c');

/// Задача из базы (в том числе из корзины).
Future<Task> task(int id) async =>
    right(await getIt<TaskRepository>().getTask(id))!;
