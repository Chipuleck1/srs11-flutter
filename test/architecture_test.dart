import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Проверка правил Clean Architecture по импортам.
/// Каждая фича лежит в lib/src/<фича>/ и делится на data / domain / presentation.
void main() {
  final features = Directory('lib/src')
      .listSync()
      .whereType<Directory>()
      .toList();

  /// Все строки import во всех .dart-файлах слоя [layer] всех фич.
  List<(String, String)> imports(String layer) => [
    for (final feature in features)
      if (Directory('${feature.path}/$layer').existsSync())
        for (final f
            in Directory('${feature.path}/$layer')
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart')))
          for (final line in f.readAsLinesSync().where(
            (l) => l.startsWith('import '),
          ))
            (f.path, line),
  ];

  String report(List<(String, String)> bad) =>
      bad.map((b) => '${b.$1}: ${b.$2}').join('\n');

  test('30. Domain каждой фичи не зависит от Flutter, Drift, Dio, SharedPreferences, Data и Presentation', () {
    const forbidden = [
      'package:flutter/',
      'package:flutter_bloc',
      'package:drift',
      'package:dio',
      'package:shared_preferences',
      'package:sqlite3',
      '/data/',
      '/presentation/',
      'core/database',
      'core/rest_client',
      'core/bloc',
    ];
    final bad = imports('domain')
        .where((i) => forbidden.any(i.$2.contains))
        .toList();
    expect(bad, isEmpty, reason: report(bad));
  });

  test('31. Presentation каждой фичи не обращается к базе, DataSource и Dio напрямую', () {
    const forbidden = [
      'core/database',
      'core/rest_client',
      '/data/',
      'package:drift',
      'package:dio',
    ];
    final bad = imports('presentation')
        .where((i) => forbidden.any(i.$2.contains))
        .toList();
    expect(bad, isEmpty, reason: report(bad));
  });

  test('32. Data одной фичи не лезет в Data/Presentation другой фичи', () {
    final bad = <(String, String)>[];
    for (final (file, line) in imports('data')) {
      final own = file
          .replaceAll(r'\', '/')
          .split('lib/src/')[1]
          .split('/')
          .first;
      final m = RegExp(r'package:lab11/src/(\w+)/(data|presentation)/')
          .firstMatch(line);
      if (m != null && m.group(1) != own) bad.add((file, line));
    }
    expect(bad, isEmpty, reason: report(bad));
  });

  test('33. У каждой фичи есть все три слоя: data, domain, presentation', () {
    for (final f in features) {
      for (final layer in ['data', 'domain', 'presentation']) {
        expect(
          Directory('${f.path}/$layer').existsSync(),
          isTrue,
          reason: '${f.path}: нет слоя $layer',
        );
      }
    }
  });
}
