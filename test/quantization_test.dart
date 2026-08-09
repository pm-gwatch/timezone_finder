// Tests for the fixed-point coordinate representation.
//
// These need no boundary data and always run. That matters more here than
// elsewhere: the reference oracle quantizes with the same functions the index
// will use, so a bug in quantization corrupts both sides identically and the
// differential test cannot see it. This file is the only guard on it.

import 'package:test/test.dart';
import 'package:timezone_finder/src/quantization.dart';

void main() {
  group('quantize', () {
    test('round-trips coordinates within half a unit', () {
      const samples = <double>[
        0,
        1,
        -1,
        48.8566,
        2.3522,
        -34.6037,
        -58.3816,
        90,
        -90,
        180,
        -180,
        179.999999,
        -179.999999,
        0.0000005,
        -0.0000005,
      ];
      for (final degrees in samples) {
        final round = dequantize(quantize(degrees));
        expect(
          (round - degrees).abs(),
          lessThanOrEqualTo(0.5 / coordinateScale),
          reason: '$degrees did not round-trip',
        );
      }
    });

    test('is symmetric about zero', () {
      // A sign error in rounding would show up as an asymmetry, and would move
      // every southern or western coordinate by one unit relative to its
      // northern or eastern mirror.
      const samples = <double>[
        0.1234565,
        1.5,
        48.8566,
        179.9999994,
        0.0000004,
        0.0000006,
      ];
      for (final degrees in samples) {
        expect(
          quantize(-degrees),
          -quantize(degrees),
          reason: 'quantize is not symmetric at $degrees',
        );
      }
    });

    test('rounds half away from zero on both sides', () {
      expect(quantize(0.0000015), 2);
      expect(quantize(-0.0000015), -2);
      expect(quantize(0.0000025), 3);
      expect(quantize(-0.0000025), -3);
    });

    test('maps the extremes to the expected units', () {
      expect(quantize(180), 180 * coordinateScale);
      expect(quantize(-180), -180 * coordinateScale);
      expect(quantize(90), 90 * coordinateScale);
      expect(quantize(-90), -90 * coordinateScale);
    });

    test('stays inside the exactly-representable integer range', () {
      // 1.8e8 is far below 2^53, so the fixed-point representation is exact on
      // every Dart platform including the web. Avoid large `1 << n` in
      // assertions under dart2js: counts ≥ 32 do not behave like native shifts
      // (e.g. `1 << 53` is not 2⁵³ there).
      const twoTo53 = 9007199254740992;
      expect(quantize(180).abs(), lessThan(twoTo53));
    });
  });

  group('quantizeQueryLongitude', () {
    const eastSeam = 180 * coordinateScale;

    test('collapses the east seam onto the west one', () {
      expect(quantizeQueryLongitude(180), -eastSeam);
      expect(quantizeQueryLongitude(-180), -eastSeam);
    });

    test('collapses every longitude that quantizes to the east seam', () {
      // The regression this file exists for. Normalising the incoming double
      // against 180.0 leaves the rest of the band that rounds to +180000000
      // on the east edge, where a +x ray cast reports "outside" — producing a
      // ~5.5 cm strip that returns nothing while the values on both sides of
      // it resolve normally.
      const band = <double>[
        180.0,
        179.9999999,
        179.9999998,
        179.99999951,
        179.9999995,
      ];
      for (final degrees in band) {
        expect(
          quantize(degrees),
          eastSeam,
          reason: '$degrees is not in the east-seam band; the test is wrong',
        );
        expect(
          quantizeQueryLongitude(degrees),
          -eastSeam,
          reason: '$degrees was left on the east edge',
        );
      }
    });

    test('leaves longitudes just outside the seam band alone', () {
      expect(quantizeQueryLongitude(179.9999994), 179999999);
      expect(quantizeQueryLongitude(179.9), 179900000);
      expect(quantizeQueryLongitude(0), 0);
      expect(quantizeQueryLongitude(-179.9), -179900000);
    });

    test('needs no special case on the west side', () {
      // -180 and everything rounding to it already share one representation.
      for (final degrees in <double>[-180.0, -179.9999999, -179.9999995]) {
        expect(quantizeQueryLongitude(degrees), -eastSeam);
      }
    });

    test('agrees with plain quantize away from the seam', () {
      const samples = <double>[0, 2.3522, -58.3816, 179, -179, 90, -90];
      for (final degrees in samples) {
        expect(quantizeQueryLongitude(degrees), quantize(degrees));
      }
    });

    test('does not normalise stored vertices', () {
      // Polygon vertices keep their own representation: rewriting a vertex at
      // +180 to -180 would move geometry to the far side of the world. Only
      // query longitudes are collapsed.
      expect(quantize(180), eastSeam);
      expect(quantize(180), isNot(quantizeQueryLongitude(180)));
    });
  });
}
