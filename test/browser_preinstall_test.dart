/// Chrome before install. Own suite: browser_parity_test installs in
/// setUpAll. Shared index is per-isolate — nothing here may install.
@TestOn('chrome')
library;

import 'package:test/test.dart';
import 'package:timezone_finder/browser.dart';
import 'package:timezone_finder/src/api/location_finder.dart'
    show LocationFinder;

void main() {
  test('a lookup before install throws, naming the fix', () {
    // load_container_web.dart throws this: on web the base64 chunks are not linked,
    // so there is nothing to fall back to. The message is the only thing
    // standing between a developer and a blank page.
    expect(
      () => LocationFinder().findLocationName(2.3522, 48.8566),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('installBoundaries'), contains('browser.dart')),
        ),
      ),
    );
  });

  test('ensurePreloaded before install throws the same way', () {
    // Documented as failing exactly like a lookup. It is the call a server or
    // app makes at startup, so it must not appear to succeed and defer the
    // failure to the first real request.
    expect(ensurePreloaded(), throwsA(isA<StateError>()));
  });

  test('boundaryDataVersion before install throws rather than guessing', () {
    expect(() => boundaryDataVersion, throwsA(isA<StateError>()));
  });
}
