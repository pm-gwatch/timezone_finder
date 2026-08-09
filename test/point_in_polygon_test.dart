// Unit tests for even-odd ray-cast containment. No boundary data required.

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:timezone_finder/src/point_in_polygon.dart';

/// A ring, as interleaved quantized `[x, y]` pairs.
Int32List ring(List<List<int>> points) {
  final out = Int32List(points.length * 2);
  for (var i = 0; i < points.length; i++) {
    out[i * 2] = points[i][0];
    out[i * 2 + 1] = points[i][1];
  }
  return out;
}

/// A 100x100 square with its lower-left corner at the origin.
final square = ring([
  [0, 0],
  [100, 0],
  [100, 100],
  [0, 100],
]);

void main() {
  group('pointInRing', () {
    test('accepts interior points', () {
      expect(pointInRing(square, 50, 50), isTrue);
      expect(pointInRing(square, 1, 1), isTrue);
      expect(pointInRing(square, 99, 99), isTrue);
    });

    test('rejects exterior points on every side', () {
      expect(pointInRing(square, -1, 50), isFalse, reason: 'west');
      expect(pointInRing(square, 101, 50), isFalse, reason: 'east');
      expect(pointInRing(square, 50, -1), isFalse, reason: 'south');
      expect(pointInRing(square, 50, 101), isFalse, reason: 'north');
      expect(pointInRing(square, -1, -1), isFalse, reason: 'diagonal');
    });

    test('rejects points beyond the ray, not just beside it', () {
      // A +x ray from a point east of the shape crosses nothing. A point west
      // of it crosses twice. Both are outside, and an implementation that
      // counted crossings without parity would get one of them wrong.
      expect(pointInRing(square, 200, 50), isFalse);
      expect(pointInRing(square, -200, 50), isFalse);
    });

    test('handles a closed ring that repeats its first vertex', () {
      // GeoJSON rings are closed: the last coordinate equals the first. The
      // repeated edge is degenerate and must contribute nothing.
      final closed = ring([
        [0, 0],
        [100, 0],
        [100, 100],
        [0, 100],
        [0, 0],
      ]);
      expect(pointInRing(closed, 50, 50), isTrue);
      expect(pointInRing(closed, 150, 50), isFalse);
    });

    test('handles concave shapes', () {
      // A C-shape opening east. The notch is enclosed by the bounding box but
      // is outside the polygon — a bbox-only test would get this wrong, which
      // is why the bbox check in the oracle is an optimisation and not the
      // answer.
      final cShape = ring([
        [0, 0],
        [100, 0],
        [100, 30],
        [30, 30],
        [30, 70],
        [100, 70],
        [100, 100],
        [0, 100],
      ]);
      expect(pointInRing(cShape, 10, 50), isTrue, reason: 'the spine');
      expect(pointInRing(cShape, 50, 50), isFalse, reason: 'inside the notch');
      expect(pointInRing(cShape, 50, 10), isTrue, reason: 'lower arm');
      expect(pointInRing(cShape, 50, 90), isTrue, reason: 'upper arm');
    });

    test('counts a vertex at the ray height exactly once', () {
      // The classic ray-casting trap. A ray passing exactly through a vertex
      // can count both adjacent edges, flipping parity twice and reporting an
      // interior point as outside. The asymmetric `(yi > py) != (yj > py)`
      // test is what prevents it.
      final diamond = ring([
        [50, 0],
        [100, 50],
        [50, 100],
        [0, 50],
      ]);
      expect(pointInRing(diamond, 50, 50), isTrue, reason: 'centre');
      // y = 50 passes through both the east and west vertices.
      expect(pointInRing(diamond, 10, 50), isTrue);
      expect(pointInRing(diamond, 90, 50), isTrue);
      expect(pointInRing(diamond, -10, 50), isFalse);
      expect(pointInRing(diamond, 110, 50), isFalse);
    });

    test('is not confused by horizontal edges', () {
      // Horizontal edges have yi == yj, so the crossing test is false and they
      // are skipped. A step shape puts several at the same height as the query.
      final steps = ring([
        [0, 0],
        [100, 0],
        [100, 50],
        [60, 50],
        [60, 80],
        [0, 80],
      ]);
      expect(pointInRing(steps, 30, 50), isTrue);
      expect(
        pointInRing(steps, 80, 50),
        isFalse,
        reason: 'above the step, outside',
      );
      expect(pointInRing(steps, 80, 40), isTrue, reason: 'below the step');
      expect(pointInRing(steps, 30, 79), isTrue);
      expect(pointInRing(steps, 30, 81), isFalse);
    });

    test('treats degenerate rings as enclosing nothing', () {
      expect(pointInRing(ring([]), 0, 0), isFalse);
      expect(
        pointInRing(
          ring([
            [0, 0],
          ]),
          0,
          0,
        ),
        isFalse,
      );
      expect(
        pointInRing(
          ring([
            [0, 0],
            [10, 10],
          ]),
          5,
          5,
        ),
        isFalse,
      );
    });

    test('works at the extremes of the coordinate range', () {
      // The products reach ~1.3e17 for antipodal coordinates. If that
      // overflowed, containment here would be arbitrary.
      final world = ring([
        [-180000000, -90000000],
        [180000000, -90000000],
        [180000000, 90000000],
        [-180000000, 90000000],
      ]);
      expect(pointInRing(world, 0, 0), isTrue);
      expect(pointInRing(world, -179999999, -89999999), isTrue);
      expect(pointInRing(world, 179999999, 89999999), isTrue);

      // A far-eastern sliver, queried from the far west: the widest possible
      // (px - xi) multiplied by the tallest possible dy.
      final sliver = ring([
        [179999000, -90000000],
        [180000000, -90000000],
        [180000000, 90000000],
        [179999000, 90000000],
      ]);
      expect(pointInRing(sliver, -180000000, 0), isFalse);
      expect(pointInRing(sliver, 179999500, 0), isTrue);
    });

    test('is consistent for adjacent polygons sharing a border', () {
      // Two squares meeting at x = 100. A point on the shared edge must belong
      // to exactly one of them, or zones would overlap or leave a gap along
      // every border in the dataset.
      final west = square;
      final east = ring([
        [100, 0],
        [200, 0],
        [200, 100],
        [100, 100],
      ]);
      final onBorder = [pointInRing(west, 100, 50), pointInRing(east, 100, 50)];
      expect(
        onBorder.where((inside) => inside).length,
        1,
        reason:
            'a point on a shared border belongs to exactly one side, '
            'got $onBorder',
      );
    });

    test('resolves an edge point to the polygon lying east of it', () {
      // The convention, not merely that there is one. A +x ray from a point on
      // a WEST edge crosses the interior and reads as inside; from a point on
      // an EAST edge it leaves immediately and reads as outside.
      //
      // This is pinned because `quantizeQueryLongitude` depends on it: the
      // antimeridian seam maps +180 to -180 precisely because the -180 side
      // presents a west edge and resolves, while +180 presents an east edge
      // and does not. Flip this convention and that fix silently inverts.
      //
      // "Exactly one side owns a border point" is preserved by the opposite
      // convention too, so that test alone cannot catch a swap.
      expect(pointInRing(square, 0, 50), isTrue, reason: 'west edge → inside');
      expect(
        pointInRing(square, 100, 50),
        isFalse,
        reason: 'east edge → outside',
      );
    });
  });

  group('pointInPolygon', () {
    final hole = ring([
      [40, 40],
      [60, 40],
      [60, 60],
      [40, 60],
    ]);

    test('excludes points inside a hole', () {
      expect(pointInPolygon(square, [], 50, 50), isTrue);
      expect(pointInPolygon(square, [hole], 50, 50), isFalse);
      expect(
        pointInPolygon(square, [hole], 20, 20),
        isTrue,
        reason: 'inside the outer ring, outside the hole',
      );
    });

    test('still excludes points outside the outer ring', () {
      expect(pointInPolygon(square, [hole], 500, 500), isFalse);
    });

    test('handles several holes', () {
      final second = ring([
        [10, 10],
        [20, 10],
        [20, 20],
        [10, 20],
      ]);
      expect(pointInPolygon(square, [hole, second], 15, 15), isFalse);
      expect(pointInPolygon(square, [hole, second], 50, 50), isFalse);
      expect(pointInPolygon(square, [hole, second], 80, 80), isTrue);
    });

    test('models an enclave: a hole is where another zone lives', () {
      // Lesotho inside South Africa. The surrounding zone must reject the
      // point, and the enclave's own polygon must accept it.
      final surrounding = square;
      final enclave = hole;
      expect(pointInPolygon(surrounding, [enclave], 50, 50), isFalse);
      expect(pointInPolygon(enclave, [], 50, 50), isTrue);
    });
  });
}
