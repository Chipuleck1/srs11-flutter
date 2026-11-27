import 'package:flutter_test/flutter_test.dart';

import 'package:lab11/core/di/injection.dart';
import 'package:lab11/core/error/failures.dart';
import 'package:lab11/src/server_import/domain/usecases/import_from_server_usecase.dart';
import 'package:lab11/src/server_import/presentation/bloc/import_cubit.dart';

import 'helpers.dart';

const _users = [
  {'id': 1, 'name': 'Leanne Graham', 'email': 'Sincere@april.biz'},
  {'id': 2, 'name': 'Ervin Howell', 'email': 'Shanna@melissa.tv'},
];
const _todos = [
  {'id': 1, 'userId': 1, 'title': 'delectus aut autem', 'completed': false},
  {'id': 2, 'userId': 2, 'title': 'quis ut nam', 'completed': true},
];

/// НОВАЯ ФУНКЦИЯ «Импорт с сервера» + централизованная обработка ошибок.
void main() {
  late FakeServer server;

  setUp(() async {
    server = await setUpApp();
    server.handler = (o) => o.path == '/users' ? _users : _todos;
  });
  tearDown(tearDownApp);

  ImportFromServerUseCase useCase() => getIt<ImportFromServerUseCase>();

  test('19. успешный импорт: проект, пользователи, задачи и история', () async {
    final r = right(await useCase()(20));

    expect(r.usersCreated, 2);
    expect(r.tasksCreated, 2);
    expect(await count('projects'), 1);
    expect(await count('project_members'), 2);
    expect(await count('task_history'), 2);
    expect(server.requests.last.queryParameters['_limit'], 20);

    // повторный импорт не дублирует пользователей с тем же email
    final again = right(await useCase()(20));
    expect(again.usersReused, 2);
    expect(await count('users'), 2);
  });

  test('20. нет интернета → NetworkFailure', () async {
    server.offline = true;
    expect(left(await useCase()(10)), isA<NetworkFailure>());
  });

  test('21. HTTP 500 → ServerFailure', () async {
    server.status = 500;
    expect(left(await useCase()(10)), isA<ServerFailure>());
  });

  test('22. HTTP 401 → UnauthorizedFailure', () async {
    server.status = 401;
    expect(left(await useCase()(10)), isA<UnauthorizedFailure>());
  });

  test(
    '23. HTTP 400 → ValidationFailure, текст без технических деталей',
    () async {
      server.status = 400;
      final f = left(await useCase()(10));
      expect(f, isA<ValidationFailure>());
      expect(f.message, isNot(contains('DioException')));
    },
  );

  test('24. некорректный JSON → ServerFailure, приложение не падает', () async {
    server.handler = (_) => [
      {'title': 'нет id'},
    ];
    expect(left(await useCase()(10)), isA<ServerFailure>());
    expect(await count('tasks'), 0);
  });

  test(
    '25. неверный параметр → ValidationFailure без запроса к серверу',
    () async {
      expect(left(await useCase()(0)), isA<ValidationFailure>());
      expect(server.requests, isEmpty);
    },
  );

  /// Все состояния, которые Cubit выдаст за время [act].
  Future<List<ImportState>> states(
    Future<void> Function(ImportCubit c) act,
  ) async {
    final cubit = getIt<ImportCubit>();
    final out = <ImportState>[];
    final sub = cubit.stream.listen(out.add);
    await act(cubit);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    await cubit.close();
    return out;
  }

  test('26. ImportCubit: Loading -> Success', () async {
    expect(await states((c) => c.start(10)), [
      isA<ImportLoading>(),
      isA<ImportSuccess>(),
    ]);
  });

  test('27. ImportCubit: пустой ответ -> Empty State', () async {
    server.handler = (_) => [];
    expect(await states((c) => c.start(10)), [
      isA<ImportLoading>(),
      isA<ImportEmpty>(),
    ]);
  });

  test(
    '28. ImportCubit: ошибка сети -> Error с повтором, повтор успешен',
    () async {
      server.offline = true;
      final result = await states((c) async {
        await c.start(10);
        server.offline = false;
        await c.retry();
      });
      expect(result, [
        isA<ImportLoading>(),
        isA<ImportError>().having((e) => e.canRetry, 'canRetry', true),
        isA<ImportLoading>(),
        isA<ImportSuccess>(),
      ]);
    },
  );

  test(
    '29. ImportCubit: повторное нажатие во время загрузки игнорируется',
    () async {
      await states((c) => Future.wait<void>([c.start(10), c.start(10)]));
      expect(server.requests.where((r) => r.path == '/users').length, 1);
    },
  );
}
