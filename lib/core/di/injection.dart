import 'package:dio/dio.dart' show HttpClientAdapter;
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lab11/core/database/app_database.dart';
import 'package:lab11/core/rest_client/rest_client.dart';
import 'package:lab11/core/di/dashboard_di.dart';
import 'package:lab11/core/di/home_di.dart';
import 'package:lab11/core/di/performance_di.dart';
import 'package:lab11/core/di/projects_di.dart';
import 'package:lab11/core/di/server_import_di.dart';
import 'package:lab11/core/di/tasks_di.dart';
import 'package:lab11/core/di/trash_di.dart';
import 'package:lab11/core/di/users_di.dart';

final getIt = GetIt.instance;

/// Единая точка регистрации зависимостей.
/// Сначала общие сервисы (база, HTTP, настройки), затем каждая фича
/// регистрирует свои DataSource → Repository → UseCase → Cubit в своём файле `<фича>_di.dart`.
/// [executor], [prefs], [httpAdapter] подменяются в тестах.
Future<void> configureDependencies({
  QueryExecutor? executor,
  SharedPreferences? prefs,
  HttpClientAdapter? httpAdapter,
}) async {
  // 1. Общие внешние сервисы (одни на всё приложение)
  getIt
    ..registerLazySingleton<AppDatabase>(
      () => AppDatabase(executor),
      dispose: (db) => db.close(),
    )
    ..registerSingleton<SharedPreferences>(
      prefs ?? await SharedPreferences.getInstance(),
    )
    ..registerLazySingleton<RestClient>(() => RestClient(adapter: httpAdapter));

  // 2. Фичи. Порядок: от тех, от кого зависят другие, к зависимым
  //    (задачам нужны проекты, корзина и статистика работают с задачами).
  registerUsersFeature(getIt);
  registerProjectsFeature(getIt);
  registerTasksFeature(getIt);
  registerTrashFeature(getIt);
  registerDashboardFeature(getIt);
  registerPerformanceFeature(getIt);
  registerServerImportFeature(getIt);
  registerHomeFeature(getIt);
}
