# TaskFlow — Clean Architecture (СРС 11)

Рефакторинг приложения **TaskFlow** (лабораторная № 10: проекты, задачи, SQLite/Drift)
по принципам **Clean Architecture**. Новое приложение не создавалось — переработан существующий проект.

Стек: Flutter · **flutter_bloc (Cubit)** · **get_it** (DI) · **fpdart** (`Either<Failure, T>`) ·
Drift/SQLite · Dio (сервер) · SharedPreferences. Тема: чёрный фон и красные акценты.

## Запуск

```bash
flutter pub get
dart run build_runner build
flutter run
flutter test
```

## Структура

Структура точно как в задании (`src/data`, `src/domain`, `src/presentation` с их папками),
а **внутри каждой папки — отдельная подпапка на каждую страницу**.
Всё, что относится к странице (entity, репозиторий, usecase, datasource, cubit, экран),
лежит в подпапках с её именем.

```
lib/
├── components/                общие виджеты (аватар, пустое состояние, ViewStateView…)
├── constants/                 тема и цвета
├── models/                    enum-ы и DTO сервера (models/server_import/)
├── core/
│   ├── rest_client/           HTTP-клиент (Dio) → исключения Data
│   ├── database/              таблицы Drift, миграции
│   ├── error/                 Failure, исключения, ErrorHandler
│   ├── usecase/  bloc/  validation/
│   └── di/                    injection.dart + <страница>_di.dart для каждой страницы
├── src/
│   ├── data/
│   │   ├── datasources/       home/ dashboard/ projects/ tasks/ users/ trash/ performance/ server_import/
│   │   ├── mapper/            projects/ tasks/ users/
│   │   └── repositories/      home/ dashboard/ projects/ tasks/ users/ trash/ performance/ server_import/
│   ├── domain/
│   │   ├── entities/          dashboard/ projects/ tasks/ users/ performance/ server_import/
│   │   ├── repositories/      home/ dashboard/ projects/ tasks/ users/ trash/ performance/ server_import/
│   │   └── usecases/          home/ dashboard/ projects/ tasks/ users/ trash/ performance/ server_import/
│   └── presentation/
│       ├── pages/             home/ dashboard/ projects/ tasks/ users/ trash/ performance/ server_import/
│       ├── widgets/           tasks/ users/
│       └── bloc/              home/ dashboard/ projects/ tasks/ users/ trash/ performance/ server_import/
└── main.dart
```

Пример — всё, что относится к странице **Корзина** (`trash`):

| Слой | Файл |
|---|---|
| domain/repositories | `src/domain/repositories/trash/trash_repository.dart` |
| domain/usecases | `src/domain/usecases/trash/trash_usecases.dart` |
| data/datasources | `src/data/datasources/trash/trash_local_data_source.dart` |
| data/repositories | `src/data/repositories/trash/trash_repository_impl.dart` |
| presentation/bloc | `src/presentation/bloc/trash/trash_cubit.dart` |
| presentation/pages | `src/presentation/pages/trash/trash_page.dart` |
| DI | `core/di/trash_di.dart` |

**Направление зависимостей — внутрь:** `presentation → domain ← data`.
Data одной страницы не обращается к data другой страницы — это проверяют тесты 30–33.

```
Page ──► Cubit ──► UseCase ──► Repository (abstract, domain)
                                     ▲
                       RepositoryImpl (data) ──► DataSource ──► SQLite / сервер
```

## Domain Layer

Для каждой функциональности: **Entity → абстрактный Repository → UseCase**.
Вся бизнес-логика перенесена из репозиториев в UseCase-ы, например:

```dart
class CreateUserUseCase implements UseCase<int, ({String name, String email})> {
  Future<Either<Failure, int>> call(p) => eitherDo(($) async {
    final name = await $(Validators.text(p.name, 'Имя'));
    final email = await $(Validators.email(p.email));
    if (await $(_repo.emailExists(email))) fail(const DuplicateEmailFailure());
    return $(_repo.createUser(name: name, email: email));
  });
}
```

Правила в Domain: уникальный email; нельзя удалить пользователя с незавершёнными задачами;
исполнитель — только участник проекта; не больше 3 задач на один дедлайн; комментарий удаляет
только автор; нельзя создать задачу без проекта; Undo статуса.

## Data Layer

- **DataSource**: 8 локальных (SQLite через Drift) + `ImportRemoteDataSource` (сервер через RestClient).
- **DTO/Models**: строки Drift (`UserRow`, `TaskRow`…) и модели API (`RemoteUserModel`, `RemoteTodoModel`).
- **Mapper**: `row.toEntity()` — в Presentation попадают только сущности Domain.
- **RepositoryImpl**: вызывает DataSource и через `ErrorHandler.guard` превращает исключения в `Failure`.
- Транзакции (задача + история, переназначение, Undo) остаются в DataSource.

## Обработка ошибок (централизованно)

| Ситуация | Исключение Data | Failure |
|---|---|---|
| Нет интернета, таймаут | `NetworkException` | `NetworkFailure` |
| HTTP 500 | `ServerException` | `ServerFailure` |
| HTTP 401 | `UnauthorizedException` | `UnauthorizedFailure` |
| HTTP 400 | `BadRequestException` | `ValidationFailure` |
| Некорректный JSON | `ParseException` | `ServerFailure` |
| Ошибка SQLite | `SqliteException` | `DatabaseFailure` / `ValidationFailure` |
| Нарушение бизнес-правила | — | подвиды `ValidationFailure` |
| Пустой результат | — | состояние **Empty** |
| Всё остальное | — | `UnknownFailure` |

`RestClient` переводит ошибки Dio в исключения Data Layer, `ErrorHandler` переводит их в `Failure`.
Пользователь видит только понятный текст (`failure.message`), технические детали пишутся в лог.

## Presentation Layer

- Экраны не делают запросов и не содержат бизнес-логики: только `Cubit`.
- Состояния `ViewInitial / ViewLoading / ViewLoaded / ViewEmpty / ViewError` + единый виджет `ViewStateView` с кнопкой **«Повторить»**.
- Без лишних запросов: поиск с debounce 300 мс, защита от повторной подгрузки страницы и от двойного нажатия «Сохранить» / «Загрузить».

## Dependency Injection (GetIt)

`core/di/injection.dart` регистрирует общие сервисы (база, HTTP, настройки) и вызывает
регистрацию каждой страницы из своего файла: `core/di/home_di.dart`, `core/di/tasks_di.dart` и т.д.
В каждом таком файле по порядку: **DataSource → Repository → UseCase → Cubit**.
Экраны получают Cubit через `getIt<…>()`, Cubit-ы получают только UseCase-ы.
Тесты используют тот же DI, подменяя базу (SQLite в памяти) и сервер (поддельный адаптер Dio).

## Новая функция: «Импорт с сервера»

Меню ⋮ → **Импорт с сервера**. Загружает пользователей (`GET /users`) и задачи (`GET /todos`)
с JSONPlaceholder, создаёт новый проект и сохраняет всё в SQLite одной транзакцией
(пользователи с существующим email не дублируются).

Сделано по Clean Architecture: `ImportPage → ImportCubit → ImportFromServerUseCase →
ImportRepository → ImportRemoteDataSource + ImportLocalDataSource`.
Состояния: Initial, Loading, Success, **Empty**, **Error** с кнопкой
**повторной отправки неудачного запроса**.

## Тесты — 34, все проходят

| Файл | Что проверяет |
|---|---|
| `domain_test.dart` (1–18) | правила UseCase-ов: email, удаление, участники, транзакция, Undo, лимит, корзина, комментарии, поиск/фильтры/пагинация, статистика |
| `import_test.dart` (19–29) | импорт, NetworkFailure, 500, 401, 400, плохой JSON, Empty, Cubit: Loading→Success, повтор, защита от двойного запроса |
| `architecture_test.dart` (30–33) | domain без Flutter/Drift/Dio; presentation без базы и Dio; data одной страницы не берёт data другой; у каждой страницы есть свои папки во всех слоях |
| `migration_test.dart` | миграция БД v1 → v2 |

## Скриншоты

| Обзор | Задачи | Задача |
|---|---|---|
| ![](docs/screenshots/01_dashboard.png) | ![](docs/screenshots/02_tasks.png) | ![](docs/screenshots/03_task_detail.png) |

| Импорт: успех | Импорт: нет интернета |
|---|---|
| ![](docs/screenshots/04_import_success.png) | ![](docs/screenshots/05_import_network_error.png) |
