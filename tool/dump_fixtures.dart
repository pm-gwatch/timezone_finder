/// Emits the golden fixtures as JSON, for cross-verification against external
/// implementations.
///
///     dart run tool/dump_fixtures.dart > /tmp/fixtures.json
///
/// The verification pass documented in `test/fixtures/README.md` compares
/// these expectations against Python `timezonefinder` and `tzf`. Emitting from
/// Dart rather than parsing the fixture sources with a regex keeps the check
/// honest: it reads exactly what the tests read, including escaped quotes and
/// null (open-ocean) expectations.
library;

import 'dart:convert';
import 'dart:io';

import '../test/fixtures/bootstrap_goldens.dart';
import '../test/fixtures/golden_points.dart';

void main() {
  final all = <Map<String, Object?>>[
    for (final point in bootstrapGoldens) _encode(point, 'bootstrap'),
    for (final point in goldenPoints) _encode(point, 'extended'),
  ];
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(all));
}

Map<String, Object?> _encode(GoldenPoint point, String set) =>
    <String, Object?>{
      'set': set,
      'name': point.name,
      'lat': point.latitude,
      'lon': point.longitude,
      'zone': point.zone,
      'category': point.category.name,
    };
