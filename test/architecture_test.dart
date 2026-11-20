import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Проверка правил Clean Architecture по импортам.
void main() {
  List<(String, String)> imports(String dir) => [
    for (final f
        in Directory(dir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart')))
      for (final line in f.readAsLinesSync().where(
        (l) => l.startsWith('import '),
      ))
        (f.path, line),
  ];

  test('30. Domain не зависит от Flutter, Drift, Dio, SharedPreferences и Data/Presentation', () {
    const forbidden = [
      'package:flutter/',
      'package:drift',
      'package:dio',
      'package:shared_preferences',
      'package:sqlite3',
      '/data/',
      '/presentation/',
      'core/database',
      'core/rest_client',
    ];
    final bad = imports('lib/src/domain')
        .where((i) => forbidden.any(i.$2.contains))
        .toList();
    expect(bad, isEmpty, reason: bad.map((b) => '${b.$1}: ${b.$2}').join('\n'));
  });

  test('31. Presentation не обращается к базе, DataSource и Dio напрямую', () {
    const forbidden = [
      'core/database',
      'core/rest_client',
      '/data/',
      'package:drift',
      'package:dio',
    ];
    final bad = imports('lib/src/presentation')
        .where((i) => forbidden.any(i.$2.contains))
        .toList();
    expect(bad, isEmpty, reason: bad.map((b) => '${b.$1}: ${b.$2}').join('\n'));
  });
}
