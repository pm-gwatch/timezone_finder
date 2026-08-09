// The dart2js exactness gate for point-in-polygon.
//
// `pointInRing` cross-multiplies to stay in integers. On dart2js `int` is a
// double, so those products must stay below 2^53 or edge tests silently give
// the wrong answer in browsers while the VM stays correct. `buildIndex` refuses
// to pack rings that breach the bound; nothing proved the refusal works, and
// its only call sites are GeoJSON-gated, so CI never reached it.
//
// These run from the bundled index and hand-built rings — no 51 MB cache — so
// the gate is exercised on every CI run.

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:timezone_finder/src/data/boundaries.dart' as bundled;
import 'package:timezone_finder/src/index.dart';

import '../tool/src/build_index.dart';

/// A closed ring spanning [dy] quantized units of latitude at constant
/// longitude, which is the shape that maximises the sound bound.
Int32List _verticalRing(int dy) =>
    Int32List.fromList(<int>[0, 0, 0, dy, 1000, dy, 1000, 0]);

void main() {
  group('bundled index headroom', () {
    test('every shipped edge stays exactly representable on dart2js', () {
      final index = TimeZoneIndex.fromBytes(bundled.loadContainer());
      final bound = index.maxPipSideBound();

      expect(bound, greaterThan(0), reason: 'no edges measured — bad scan');
      expect(
        bound,
        lessThan(pipDart2jsLimit),
        reason:
            'shipped rings breach the dart2js exactness bound: $bound vs '
            '$pipDart2jsLimit. Browser lookups would disagree with the VM.',
      );
    });

    test('the headroom is reported, so erosion is visible before it bites', () {
      // Deliberately loose: this is a canary, not a budget. At 2026c the
      // margin is only ~1.14x, so a tzbb release with longer edges could
      // cross the limit — and then buildIndex hard-fails rather than shipping
      // something subtly wrong. Run tool/measure_pip_bound.dart for the number.
      final index = TimeZoneIndex.fromBytes(bundled.loadContainer());
      final headroom = pipDart2jsLimit / index.maxPipSideBound();
      expect(
        headroom,
        greaterThan(1.0),
        reason: 'headroom ${headroom.toStringAsFixed(3)}x',
      );
    });
  });

  group('assertPipDart2jsSafe', () {
    test('rejects a ring whose edges cannot stay exact', () {
      // A pole-to-pole edge: 360e6 * 180e6 is well past 2^53. Asserted rather
      // than assumed, so this fixture and the accepting one below are known to
      // straddle the limit instead of both sitting on the same side of it.
      const dy = 180000000;
      expect(pipSideBound(1000, dy), greaterThanOrEqualTo(pipDart2jsLimit));
      expect(
        () => assertPipDart2jsSafe(<Int32List>[_verticalRing(dy)]),
        throwsA(isA<StateError>()),
      );
    });

    test('accepts a ring just inside the bound', () {
      // 360e6 * 25e6 = 9.0e15, just under 2^53 = 9.007e15.
      const dy = 25000000;
      expect(pipSideBound(1000, dy), lessThan(pipDart2jsLimit));
      expect(
        () => assertPipDart2jsSafe(<Int32List>[_verticalRing(dy)]),
        returnsNormally,
      );
    });

    test('rejects when only one ring out of many is unsafe', () {
      // The scan must not stop at the first ring it likes.
      expect(
        () => assertPipDart2jsSafe(<Int32List>[
          _verticalRing(1000),
          _verticalRing(1000),
          _verticalRing(180000000),
        ]),
        throwsA(isA<StateError>()),
      );
    });

    test('an empty ring set is vacuously safe', () {
      expect(() => assertPipDart2jsSafe(<Int32List>[]), returnsNormally);
    });
  });

  group('pipSideBound', () {
    test('is the sound bound from the doc comment', () {
      expect(pipSideBound(0, 0), 0);
      expect(pipSideBound(7, 3), 360000000 * 3 + 3 * 7);
    });

    test('grows with both extents, so neither term is dropped', () {
      expect(pipSideBound(10, 5), greaterThan(pipSideBound(1, 5)));
      expect(pipSideBound(5, 10), greaterThan(pipSideBound(5, 1)));
    });
  });
}
