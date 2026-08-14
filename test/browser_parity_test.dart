/// Chrome: install `.bin`, then the same [bootstrapGoldens] as the VM.
@TestOn('chrome')
library;

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:timezone_finder/browser.dart';
import 'package:timezone_finder/src/generated/boundaries_bin.dart'
    show boundariesBinLength;
import 'package:timezone_finder/src/api/location_finder.dart'
    show LocationFinder;

import 'fixtures/bootstrap_goldens.dart';
import 'fixtures/overlap_pins.dart';

void main() {
  late LocationFinder finder;

  setUpAll(() async {
    await initializeBoundaries();
    finder = LocationFinder();
    expect(boundaryDataVersion, '2026c');
    expect(finder.availableLocationNames.length, 419);
  });

  // Load-bearing parity: shared fixtures with the VM suite. Do not delete this
  // in favour of the smoke list below — that list is not a differential.
  test('bootstrap goldens match (VM/Chrome parity)', () {
    for (final point in bootstrapGoldens) {
      expect(
        finder.findLocationName(point.longitude, point.latitude),
        point.zone,
        reason: '$point',
      );
    }
  });

  test('open ocean is null', () {
    expect(finder.findLocationName(-140.0, 0.0), isNull);
  });

  test('one overlap pin follows the documented tiebreak', () {
    final pin = overlapPins.first;
    expect(
      finder.findLocationName(pin.longitude, pin.latitude),
      pin.selected,
      reason: pin.description,
    );
  });

  test('city smoke list', () {
    // Hardcoded expectations for a few well-known points — not a runtime
    // compare against the VM. Parity proof is bootstrap goldens above.
    const samples = <(double lng, double lat, String? zone)>[
      (2.3522, 48.8566, 'Europe/Paris'),
      (13.4050, 52.5200, 'Europe/Berlin'),
      (-74.0060, 40.7128, 'America/New_York'),
      (151.2093, -33.8688, 'Australia/Sydney'),
      (139.6917, 35.6895, 'Asia/Tokyo'),
      (37.6173, 55.7558, 'Europe/Moscow'),
      (-0.1278, 51.5074, 'Europe/London'),
      (72.8777, 19.0760, 'Asia/Kolkata'),
      (-58.3816, -34.6037, 'America/Argentina/Buenos_Aires'),
      (31.2357, 30.0444, 'Africa/Cairo'),
      (-140.0, 0.0, null),
      (0.0, 0.0, null),
    ];
    for (final (lng, lat, zone) in samples) {
      expect(finder.findLocationName(lng, lat), zone, reason: '($lng, $lat)');
    }
  });

  test('ensurePreloaded succeeds after install', () async {
    await ensurePreloaded();
    expect(boundaryDataVersion, isNotEmpty);
  });

  test('corrupt bytes throw IndexFormatException', () {
    expect(
      () => installBoundaries(Uint8List.fromList(<int>[1, 2, 3, 4])),
      throwsA(isA<IndexFormatException>()),
    );
  });

  group('initializeBoundaries failure modes', () {
    // Chrome-only: this is the fetch error path. VM never compiles
    // browser.dart. A successful install is already proven by setUpAll.

    test('a missing URL fails as a fetch problem, not a format one', () {
      expect(
        initializeBoundaries(
          'packages/timezone_finder/data/no_such_boundaries.bin',
        ),
        throwsA(
          isA<BoundariesInitException>().having(
            (e) => e.message,
            'message',
            contains('status'),
          ),
        ),
      );
    });

    test('a right-URL wrong-body response is rejected on size', () {
      // The documented failure this guard exists for: a host answering
      // `packages/…` with an HTML 404 page. Serving a real file of the wrong
      // length stands in for it — the bytes must never reach the decoder,
      // where they would surface as IndexFormatException instead.
      expect(
        initializeBoundaries('packages/timezone_finder/timezone_finder.dart'),
        throwsA(
          // Asserted on the message so this cannot pass by 404-ing like the
          // test above: only the length check says "expected".
          isA<BoundariesInitException>().having(
            (e) => e.message,
            'message',
            allOf(contains('expected'), contains('$boundariesBinLength')),
          ),
        ),
      );
    });

    test('a failed fetch leaves the installed index intact', () {
      expect(finder.findLocationName(2.3522, 48.8566), 'Europe/Paris');
    });
  });
}
