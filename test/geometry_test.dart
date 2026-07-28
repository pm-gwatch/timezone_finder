// Tests for polygon area and the overlap precedence rule.
//
// These need no boundary data and always run. `comparePrecedence` decides
// which identifier is returned in the documented overlap regions — mostly
// disputed territories — so it has to be a genuine total order, not merely
// one that happens to sort this dataset acceptably.

import 'dart:typed_data';

import 'package:test/test.dart';

import '../tool/src/geometry.dart';

/// A polygon's sort key: everything the precedence rule looks at.
typedef Key = ({double area, String zone});

int compareKeys(Key x, Key y) =>
    comparePrecedence(x.area, x.zone, y.area, y.zone);

/// A closed ring, as interleaved quantized `[x, y]` pairs.
Int32List ring(List<List<int>> points) {
  final out = Int32List(points.length * 2);
  for (var i = 0; i < points.length; i++) {
    out[i * 2] = points[i][0];
    out[i * 2 + 1] = points[i][1];
  }
  return out;
}

void main() {
  group('ringArea', () {
    test('computes the area of a unit square', () {
      expect(
        ringArea(
          ring([
            [0, 0],
            [10, 0],
            [10, 10],
            [0, 10],
          ]),
        ),
        100.0,
      );
    });

    test('ignores winding direction', () {
      final clockwise = ring([
        [0, 0],
        [0, 10],
        [10, 10],
        [10, 0],
      ]);
      final counterClockwise = ring([
        [0, 0],
        [10, 0],
        [10, 10],
        [0, 10],
      ]);
      expect(ringArea(clockwise), ringArea(counterClockwise));
    });

    test('is translation-invariant', () {
      // The implementation relies on this to keep products small, so it is
      // worth asserting rather than assuming.
      final atOrigin = ring([
        [0, 0],
        [100, 0],
        [100, 50],
        [0, 50],
      ]);
      final farAway = ring([
        [179000000, 89000000],
        [179000100, 89000000],
        [179000100, 89000050],
        [179000000, 89000050],
      ]);
      expect(ringArea(farAway), ringArea(atOrigin));
    });

    test('handles negative coordinates identically', () {
      final positive = ring([
        [0, 0],
        [10, 0],
        [10, 10],
        [0, 10],
      ]);
      final negative = ring([
        [0, 0],
        [-10, 0],
        [-10, -10],
        [0, -10],
      ]);
      expect(ringArea(negative), ringArea(positive));
    });

    test('gives degenerate rings zero area', () {
      expect(ringArea(ring([])), 0.0);
      expect(
        ringArea(
          ring([
            [0, 0],
          ]),
        ),
        0.0,
      );
      expect(
        ringArea(
          ring([
            [0, 0],
            [10, 10],
          ]),
        ),
        0.0,
      );
    });

    test('never returns a negative or non-finite area', () {
      final collinear = ring([
        [0, 0],
        [10, 10],
        [20, 20],
        [30, 30],
      ]);
      expect(ringArea(collinear), 0.0);
      expect(ringArea(collinear).isFinite, isTrue);
      expect(ringArea(collinear), isNonNegative);
    });
  });

  group('netPolygonArea', () {
    test('subtracts holes from the outer ring', () {
      final outer = ring([
        [0, 0],
        [100, 0],
        [100, 100],
        [0, 100],
      ]);
      final hole = ring([
        [10, 10],
        [20, 10],
        [20, 20],
        [10, 20],
      ]);
      expect(netPolygonArea(outer, []), 10000.0);
      expect(netPolygonArea(outer, [hole]), 10000.0 - 100.0);
      expect(netPolygonArea(outer, [hole, hole]), 10000.0 - 200.0);
    });
  });

  group('comparePrecedence', () {
    test('prefers the smaller polygon', () {
      expect(comparePrecedence(1, 'A', 2, 'B'), isNegative);
      expect(comparePrecedence(2, 'A', 1, 'B'), isPositive);
    });

    test('breaks exact ties on identifier', () {
      expect(
        comparePrecedence(5, 'Asia/Hebron', 5, 'Asia/Jerusalem'),
        isNegative,
      );
      expect(
        comparePrecedence(5, 'Asia/Jerusalem', 5, 'Asia/Hebron'),
        isPositive,
      );
      expect(comparePrecedence(5, 'Same', 5, 'Same'), 0);
    });

    test('is reflexive and antisymmetric', () {
      const areas = <double>[0, 1, 1e-9, 1e12, 1.0000000005];
      const zones = <String>['A', 'B', 'Zzz'];
      for (final a in areas) {
        for (final za in zones) {
          expect(comparePrecedence(a, za, a, za), 0);
          for (final b in areas) {
            for (final zb in zones) {
              expect(
                comparePrecedence(a, za, b, zb).sign,
                -comparePrecedence(b, zb, a, za).sign,
                reason: 'not antisymmetric for ($a,$za) vs ($b,$zb)',
              );
            }
          }
        }
      }
    });

    test('is transitive — the property a tolerance would break', () {
      // The regression this group exists for. A relative-tolerance comparator
      // ties values that are close and orders values that are far, and
      // "close" is not an equivalence relation: closeness does not compose.
      //
      // These three areas are the concrete counterexample at a 1e-9 relative
      // tolerance. a ties with b, b ties with c, yet a sorts strictly before
      // c — so the comparator contradicts itself and List.sort may emit an
      // arbitrary order. Here that order decides which identifier is returned
      // in a disputed territory.
      // Steps of 0.6e-9 relative: each adjacent pair falls inside the 1e-9
      // tolerance, but a and c are 1.2e-9 apart and fall outside it.
      const a = 1.0;
      const b = 1.0 + 6e-10;
      const c = 1.0 + 12e-10;

      // Demonstrate that the OLD rule really was inconsistent on this triple,
      // so the test is anchored to the real defect rather than to a guess.
      int oldRule(double x, String zx, double y, String zy) {
        final scale = x.abs() > y.abs() ? x.abs() : y.abs();
        if ((x - y).abs() > 1e-9 * scale) return x.compareTo(y);
        return zx.compareTo(zy);
      }

      expect(oldRule(a, 'Z', b, 'Z'), 0, reason: 'old rule tied a and b');
      expect(oldRule(b, 'Z', c, 'Z'), 0, reason: 'old rule tied b and c');
      expect(
        oldRule(a, 'Z', c, 'Z'),
        isNot(0),
        reason:
            'old rule separated a and c despite tying both to b — '
            'that is the non-transitivity',
      );

      // The current rule is consistent on the same triple.
      expect(comparePrecedence(a, 'Z', b, 'Z'), isNegative);
      expect(comparePrecedence(b, 'Z', c, 'Z'), isNegative);
      expect(comparePrecedence(a, 'Z', c, 'Z'), isNegative);
    });

    test('is transitive across an exhaustive sample', () {
      final keys = <Key>[
        for (final area in <double>[
          0,
          1e-12,
          1e-9,
          1.0,
          1.0 + 6e-10,
          1.0 + 12e-10,
          2.0,
          1e12,
        ])
          for (final zone in <String>['A', 'M', 'Z']) (area: area, zone: zone),
      ];
      const cmp = compareKeys;

      for (final x in keys) {
        for (final y in keys) {
          for (final z in keys) {
            if (cmp(x, y) <= 0 && cmp(y, z) <= 0) {
              expect(
                cmp(x, z),
                lessThanOrEqualTo(0),
                reason: 'transitivity broken: $x <= $y <= $z but not $x <= $z',
              );
            }
          }
        }
      }
    });

    test('sorting is stable and deterministic under permutation', () {
      // A comparator that is a total order sorts every permutation of the same
      // input to the same result. An inconsistent one need not.
      final base = <Key>[
        (area: 1.0, zone: 'Europe/Rome'),
        (area: 1.0 + 6e-10, zone: 'Europe/Paris'),
        (area: 1.0 + 12e-10, zone: 'Europe/Berlin'),
        (area: 0.5, zone: 'Europe/Madrid'),
        (area: 1.0, zone: 'Europe/Athens'),
      ];
      const cmp = compareKeys;

      final expected = (base.toList()..sort(cmp)).map((e) => e.zone).toList();
      for (var shift = 0; shift < base.length; shift++) {
        final rotated = <Key>[...base.skip(shift), ...base.take(shift)]
          ..sort(cmp);
        expect(
          rotated.map((e) => e.zone).toList(),
          expected,
          reason: 'sort result depends on input order at shift $shift',
        );
      }
    });
  });
}
