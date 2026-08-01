// Douglas-Peucker simplification, tested on its own terms.
//
// Until now this code was only exercised through the bundled data, whose
// expected output *is* whatever simplification produces. The byte-identity
// check in bundled_data_test catches any change to it — but that is a
// regression guard, not a correctness one: had the algorithm been wrong from
// the start, it would have pinned the wrong bytes just as happily.
//
// These tests assert the properties Douglas-Peucker is supposed to have,
// independent of the dataset. Needs no boundary data.

import 'dart:typed_data';

import 'package:test/test.dart';

import '../tool/src/simplify.dart';

Int32List ring(List<List<int>> points) {
  final out = Int32List(points.length * 2);
  for (var i = 0; i < points.length; i++) {
    out[i * 2] = points[i][0];
    out[i * 2 + 1] = points[i][1];
  }
  return out;
}

List<List<int>> points(Int32List r) => <List<int>>[
  for (var i = 0; i < r.length ~/ 2; i++) <int>[r[i * 2], r[i * 2 + 1]],
];

void main() {
  group('simplifyRing', () {
    test('keeps the first and last vertex, so a ring stays closed', () {
      final original = ring([
        [0, 0],
        [10, 1],
        [20, 0],
        [30, 1],
        [40, 0],
      ]);
      final result = points(simplifyRing(original, 1000));
      expect(result.first, <int>[0, 0]);
      expect(result.last, <int>[40, 0]);
    });

    test('output is a subsequence of the input — no invented vertices', () {
      // The defining property. Simplification may only *drop* points; a
      // version that averaged or interpolated would move a border somewhere
      // the source data never put one.
      final original = ring([
        [0, 0],
        [5, 300],
        [10, -200],
        [15, 400],
        [20, 0],
        [25, 900],
        [30, 0],
      ]);
      // Compared as strings: Dart lists use identity equality, so indexOf on
      // List<List<int>> would never match.
      final input = points(original).map((p) => p.join(',')).toList();
      final result = points(
        simplifyRing(original, 250),
      ).map((p) => p.join(',')).toList();
      expect(result.length, lessThan(input.length));

      var at = 0;
      for (final p in result) {
        final found = input.indexOf(p, at);
        expect(
          found,
          greaterThanOrEqualTo(0),
          reason: '$p is not an input vertex',
        );
        at = found + 1;
      }
    });

    test('collapses a straight line to its endpoints', () {
      final straight = ring([
        for (var i = 0; i <= 20; i++) [i * 100, i * 100],
      ]);
      expect(points(simplifyRing(straight, 1)).length, 2);
    });

    test('keeps a vertex that deviates by more than the tolerance', () {
      final spike = ring([
        [0, 0],
        [100, 5000],
        [200, 0],
      ]);
      expect(simplifyRing(spike, 1000).length ~/ 2, 3);
      expect(simplifyRing(spike, 9000).length ~/ 2, 2);
    });

    test('is monotonic: a coarser tolerance never keeps more vertices', () {
      final wiggly = ring([
        for (var i = 0; i <= 200; i++) [i * 37, (i * 991) % 700 - 350],
      ]);
      var previous = 1 << 30;
      for (final tolerance in <int>[0, 1, 10, 50, 100, 500, 2000, 10000]) {
        final kept = simplifyRing(wiggly, tolerance).length ~/ 2;
        expect(
          kept,
          lessThanOrEqualTo(previous),
          reason: 'tolerance $tolerance kept more than the previous step',
        );
        previous = kept;
      }
      expect(previous, 2, reason: 'a huge tolerance should leave endpoints');
    });

    test('leaves rings too small to simplify alone', () {
      for (final small in <Int32List>[
        ring([]),
        ring([
          [1, 2],
        ]),
        ring([
          [1, 2],
          [3, 4],
        ]),
      ]) {
        expect(simplifyRing(small, 1000), small);
      }
    });

    test('handles a ring whose endpoints coincide', () {
      // GeoJSON rings repeat their first vertex last, so the segment the
      // recursion starts from has zero length. The distance test has to fall
      // back to point-to-point rather than divide by zero.
      final closed = ring([
        [0, 0],
        [1000, 0],
        [1000, 1000],
        [0, 1000],
        [0, 0],
      ]);
      final result = simplifyRing(closed, 10);
      expect(result.length ~/ 2, greaterThanOrEqualTo(4));
      expect(points(result).first, points(result).last);
    });
  });

  group('simplifyPolygon', () {
    test('drops a polygon whose outer ring collapses', () {
      final stats = SimplifyStats();
      final sliver = ring([
        [0, 0],
        [1000, 1],
        [2000, 0],
      ]);
      expect(simplifyPolygon(sliver, const <Int32List>[], 5000, stats), isNull);
      expect(stats.polygonsDropped, 1);
    });

    test('drops a hole that collapses but keeps the polygon', () {
      final stats = SimplifyStats();
      final outer = ring([
        [0, 0],
        [100000, 0],
        [100000, 100000],
        [0, 100000],
      ]);
      final tinyHole = ring([
        [500, 500],
        [600, 501],
        [700, 500],
      ]);
      final result = simplifyPolygon(outer, <Int32List>[tinyHole], 5000, stats);
      expect(result, isNotNull);
      expect(result!.holes, isEmpty);
      expect(stats.holesDropped, 1);
      expect(stats.polygonsDropped, 0);
    });

    test('keeps a hole large enough to survive', () {
      final stats = SimplifyStats();
      final outer = ring([
        [0, 0],
        [100000, 0],
        [100000, 100000],
        [0, 100000],
      ]);
      final hole = ring([
        [20000, 20000],
        [80000, 20000],
        [80000, 80000],
        [20000, 80000],
      ]);
      final result = simplifyPolygon(outer, <Int32List>[hole], 100, stats);
      expect(result!.holes, hasLength(1));
      expect(stats.holesDropped, 0);
    });

    test('accounts for every vertex it was given', () {
      final stats = SimplifyStats();
      final outer = ring([
        for (var i = 0; i <= 50; i++) [i * 1000, (i % 7) * 300],
      ]);
      final hole = ring([
        for (var i = 0; i <= 20; i++) [10000 + i * 100, 10000 + (i % 3) * 200],
      ]);
      simplifyPolygon(outer, <Int32List>[hole], 400, stats);
      expect(stats.verticesIn, 51 + 21);
      expect(stats.verticesOut, lessThan(stats.verticesIn));
      expect(stats.vertexRetention, lessThan(1));
      expect(stats.ringsIn, 2);
    });
  });
}
