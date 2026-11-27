import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Проверка правил Clean Architecture по импортам.
/// Структура: lib/src/<слой>/<вид>/<страница>/…,
/// например src/domain/usecases/tasks/task_usecases.dart.
void main() {
  /// (файл, строка import) для всех .dart-файлов слоя [layer].
  List<(String, String)> imports(String layer) => [
    for (final f
        in Directory('lib/src/$layer')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart')))
      for (final line in f.readAsLinesSync().where(
        (l) => l.startsWith('import '),
      ))
        (f.path.replaceAll(r'\', '/'), line),
  ];

  String report(List<(String, String)> bad) =>
      bad.map((b) => '${b.$1}: ${b.$2}').join('\n');

  test('30. Domain не зависит от Flutter, Drift, Dio, SharedPreferences, Data и Presentation', () {
    const forbidden = [
      'package:flutter/',
      'package:flutter_bloc',
      'package:drift',
      'package:dio',
      'package:shared_preferences',
      'package:sqlite3',
      'src/data/',
      'src/presentation/',
      'core/database',
      'core/rest_client',
      'core/bloc',
    ];
    final bad = imports('domain')
        .where((i) => forbidden.any(i.$2.contains))
        .toList();
    expect(bad, isEmpty, reason: report(bad));
  });

  test('31. Presentation не обращается к базе, DataSource и Dio напрямую', () {
    const forbidden = [
      'core/database',
      'core/rest_client',
      'src/data/',
      'package:drift',
      'package:dio',
    ];
    final bad = imports('presentation')
        .where((i) => forbidden.any(i.$2.contains))
        .toList();
    expect(bad, isEmpty, reason: report(bad));
  });

  test('32. Data одной страницы не берёт data другой страницы', () {
    final bad = <(String, String)>[];
    for (final (file, line) in imports('data')) {
      // lib/src/data/<вид>/<страница>/файл.dart
      final own = file.split('lib/src/data/')[1].split('/')[1];
      final m = RegExp(r'package:lab11/src/data/\w+/(\w+)/').firstMatch(line);
      if (m != null && m.group(1) != own) bad.add((file, line));
    }
    expect(bad, isEmpty, reason: report(bad));
  });

  test('33. У каждой страницы есть domain (usecases), data (repositories) и presentation (pages + bloc)', () {
    final pages = Directory('lib/src/presentation/pages')
        .listSync()
        .whereType<Directory>()
        .map((d) => d.path.replaceAll(r'\', '/').split('/').last)
        .toList();
    expect(pages, isNotEmpty);
    for (final page in pages) {
      for (final dir in [
        'domain/usecases',
        'domain/repositories',
        'data/repositories',
        'data/datasources',
        'presentation/pages',
        'presentation/bloc',
      ]) {
        expect(
          Directory('lib/src/$dir/$page').existsSync(),
          isTrue,
          reason: 'нет lib/src/$dir/$page',
        );
      }
    }
  });
}
